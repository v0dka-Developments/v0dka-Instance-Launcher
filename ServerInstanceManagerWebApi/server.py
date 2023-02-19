import config
import json
import subprocess
import os

"""
    here we have create server this will create server in database and this is only call by unreal engine server or the server instancer
    do not call this from client
"""


def status(connection, cursor, server_ip, message, id):
    message_data = [server_ip]
    message_query = """ select id,message,status,server_port from server_messages where server_ip=%s and status != "complete" order by id ASC limit 1 """
    cursor.execute(message_query, message_data)
    message_result = cursor.fetchone()

    if message_result == None or (len(message_result) == 0):
        connection.commit()
        return ("no messages")

    else:
        print(message_result)
        if message == None or (len(message) == 0):
            if message_result != None or (len(message_result) > 0):
                print("delete " + message_result[2])
                connection.commit()
                return (str(message_result[0]) + " " + message_result[1] + " " + str(message_result[3]))
        else:
            update_messages = [message, server_ip, id]
            update_message_query = """ update server_messages set status=%s where server_ip=%s and id=%s"""
            cursor.execute(update_message_query, update_messages)
            connection.commit()
            return "success"


def check_waiting_instances_status(connection, cursor, map_name):
    instance_data = [map_name]
    instance_query = """ select map_name from waiting_instances where map_name=%s and status != 'complete'"""
    cursor.execute(instance_query, instance_data)
    result = cursor.fetchone()

    if result == None:
        return False
    else:
        return True


def create(connection, cursor, server_ip, map_name, port):
    # we create list of value to put query database and to insert into database if query not exist
    server_data = [server_ip, map_name, port]

    query_ip_port_map = """ SELECT server_ip,map_name,port from servers where server_ip=%s and map_name=%s and port=%s
                               """
    cursor.execute(query_ip_port_map, server_data)
    result = cursor.fetchall()

    # we check if result is zero if result zero we can then insert new result we do not want same result
    if len(result) == 0:

        insert_server = """ INSERT INTO servers(server_ip,map_name,port) VALUES (%s,%s,%s)"""

        cursor.execute(insert_server, server_data)
        connection.commit()
        return "server added"
    else:
        return "Error Code 1"


def delete_all_console(connection, cursor, server_ip):
    message_data = [server_ip]
    message_query = """ delete from servers where server_ip=%s"""
    cursor.execute(message_query, message_data)
    connection.commit()
    return "success"


def delete(connection, cursor, server_ip, port):
    ## we check if the message exists if message exists and status is complete then we execute delete...
    message_data = [server_ip, port]
    message_query = """ select message,status from server_messages where server_ip=%s and server_port=%s"""
    cursor.execute(message_query, message_data)
    message_result = cursor.fetchone()

    if message_result == None or (len(message_result) == 0):
        return ("no messages")
    else:
        print(message_result[1])
        print(message_result[0])

        if (message_result[1] == "complete"):
            # we create list of value of data we look for to delete from database
            server_data = [server_ip, port]

            delete_ip_port_map = """ delete from servers where server_ip=%s and port=%s  """
            cursor.execute(delete_ip_port_map, server_data)
            connection.commit()

            return "server removed"

        else:
            return ("pending")


def master_delete(connection, cursor, password):
    if password == config.Master_Password:
        query_all_servers = """ select server_ip, map_name,port from servers"""
        cursor.execute(query_all_servers)
        result = cursor.fetchall()
        connection.commit()
        for x in result:
            ip = x[0]
            map = x[1]
            port = x[2]
            insert_message = [ip, port, "delete"]
            query_message = """ select server_ip,server_port,message from server_messages where server_ip=%s and server_port=%s and message=%s and status='pending' """
            cursor.execute(query_message, insert_message)
            result = cursor.fetchall()

            if result == None or (len(result) == 0):
                update_messages = """ insert into server_messages (server_ip,server_port,message) values(%s,%s,%s)"""
                cursor.execute(update_messages, insert_message)
                connection.commit()
            else:
                print("i cant do this already existing task")

        ## need to update a method for this ##
        # delete_servers = """ truncate servers """
        # cursor.execute(delete_servers)
        delete_waiting_instances = """ truncate waiting_instances """
        cursor.execute(delete_waiting_instances)
        connection.commit()
        return "success"
    else:
        return "error code 2"


def update_players(connection, cursor, server_ip, map_name, port, player_count):
    # we create list of value of data we look for to update the database
    server_data = [player_count, server_ip, map_name, port]

    update_players = """ update servers set players=%s where server_ip=%s and map_name=%s and port=%s
                               """
    cursor.execute(update_players, server_data)
    connection.commit()

    return "player count updated"


def request_player_server(connection, cursor, map_name):
    # we create list of value of data we look for to update the database
    server_data = [map_name]

    fetch_server = """ select players,server_ip,port from servers where map_name=%s order by players desc limit 1"""

    cursor.execute(fetch_server, server_data)
    fetch_server_result = cursor.fetchone()
    connection.commit()
    if fetch_server_result == None:
        res = check_waiting_instances_status(connection, cursor, map_name)

        if not res:
            insert_new_server = """ insert into waiting_instances (map_name) values(%s)"""

            cursor.execute(insert_new_server, server_data)
            connection.commit()
            join_map = {
                "status": "creating",
                "message": "creating server",
            }
            return (json.dumps(join_map))
        else:
            join_map = {
                "status": "waiting",
                "message": "server spin up request already exists pending...",
            }
            return (json.dumps(join_map))
    elif len(fetch_server_result) == 0:

        res = check_waiting_instances_status(connection, cursor, map_name)

        if not res:
            insert_new_server = """ insert into waiting_instances (map_name) values(%s)"""

            cursor.execute(insert_new_server, server_data)
            connection.commit()
            print("creating server")
            join_map = {
                "status": "creating",
                "message": "creating server",
            }
            return (json.dumps(join_map))

        else:
            join_map = {
                "status": "waiting",
                "message": "server spin up request already exists pending...",
            }
            return (json.dumps(join_map))
    else:
        if config.Soft_Cap > 0:

            if int(fetch_server_result[0]) > int(config.Soft_Cap):
                res = check_waiting_instances_status(connection, cursor, map_name)

                if not res:
                    insert_new_server = """ insert into waiting_instances (map_name) values(%s)"""

                    cursor.execute(insert_new_server, server_data)
                    connection.commit()
                    print("must create server due to softcap")
                    join_map = {
                        "status": "waiting",
                        "message": "waiting for server spinup",
                    }
                    return (json.dumps(join_map))
                else:
                    print("annnnn server spin up request already exists pending...")
                    join_map = {
                        "status": "waiting",
                        "message": "waiting for server spinup",
                    }
                    return (json.dumps(join_map))
            else:
                join_map = {
                    "status": "success",
                    "message": "can join",
                    "ip": fetch_server_result[1],
                    "port": fetch_server_result[2]
                }
                return (json.dumps(join_map))
        else:
            return ("fuck")


def spin_up_server(connection, cursor, requested_server):
    fetch_server = """ select id, map_name from waiting_instances where status='none' limit 1"""
    cursor.execute(fetch_server)
    fetch_server_result = cursor.fetchone()
    connection.commit()

    if fetch_server_result == None or (len(fetch_server_result) == 0):
        return ("no instances to create")
    else:
        id = int(fetch_server_result[0])
        map = str(fetch_server_result[1])
        server = str(requested_server)

        status = ["pending", server, id]
        update_map_request = """ update waiting_instances set status=%s,server_requested=%s where id=%s """
        cursor.execute(update_map_request, status)
        connection.commit()
        return (map)


def spin_up_complete(connection, cursor, requested_server, port, map_name):
    server_query = ["pending", requested_server, map_name]
    fetch_server = """select id from waiting_instances where status=%s and server_requested=%s and map_name=%s limit 1"""
    cursor.execute(fetch_server, server_query)
    fetch_server_result = cursor.fetchone()
    connection.commit()

    if fetch_server_result == None or (len(fetch_server_result) == 0):
        return ("no instances to create")
    else:
        id = fetch_server_result[0]
        status = ["complete", requested_server, id]
        update_map_request = """ update waiting_instances set status=%s,server_requested=%s where id=%s """
        cursor.execute(update_map_request, status)
        connection.commit()

        create(connection, cursor, requested_server, map_name, port)
        # status = [requested_server,map_name,port]
        # update_map_request = """ insert into servers (server_ip, map_name,port) values (%s,%s,%s) """
        # cursor.execute(update_map_request, status)
        return "success"


def download_update():
    current_directory = os.getcwd()
    print(current_directory+"/"+config.Folder)
    command = '''cd ''' + current_directory + '''/''' + config.Folder + '''; /bin/ls -Art | /bin/tail -n 1  '''  # the shell command to list screen processes
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
    output = process.communicate()
    result = output[0].decode("utf-8")
    remove_extra = result.replace('''\n''', "")
    file = current_directory + "/" + config.Folder + "/" + remove_extra

    return (file)


def admin_ui_server_manager(connection, cursor, server_id, action):

        server_query = [server_id]
        fetch_server = """select * from servers where id=%s"""
        cursor.execute(fetch_server, server_query)
        fetch_server_result = cursor.fetchone()
        connection.commit()

        if action == "force_restart":
            insert_message = [fetch_server_result[1], fetch_server_result[3], "reload:"+fetch_server_result[2], "pending"]

            query_message = """select * from server_messages where server_ip=%s and server_port=%s and message=%s and status=%s """
            cursor.execute(query_message, insert_message)
            query_message_result = cursor.fetchall()
            if (query_message_result == None or (len(query_message_result) == 0)):
                server_message = """insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s) """
                cursor.execute(server_message, insert_message)
                connection.commit()

                return "success restart has been issued"
            else:
                return "this server is already pending this action"

        if action == "stop_server":
            insert_message = [fetch_server_result[1], fetch_server_result[3], "stop:"+fetch_server_result[2], "pending"]

            query_message = """select * from server_messages where server_ip=%s and server_port=%s and message=%s and status=%s """
            cursor.execute(query_message, insert_message)
            query_message_result = cursor.fetchall()
            if (query_message_result == None or (len(query_message_result) == 0)):
                server_message = """insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s) """
                cursor.execute(server_message, insert_message)
                connection.commit()

                return "success stop has been requested"
            else:
                return "this server is already pending this action"

        return "failed"


def add_dedicated_server(connection, cursor, ip):
    query_server_data = [ip]

    query_server = """select * from dedicated_servers where server_ip=%s"""
    cursor.execute(query_server, query_server_data)
    query_server_result = cursor.fetchall()
    if (query_server_result == None or (len(query_server_result) == 0)):
        ## server does not exist lets add it
        insert_server = """insert into dedicated_servers (server_ip) values (%s)"""
        cursor.execute(insert_server, query_server_data)
        connection.commit()
        return "success added"
    else:
        connection.commit()
        return "already exists"


def admin_ui_start_map(connection, cursor, map_name, server_id):
    start_map = "start:" + map_name
    message_data = [server_id, start_map]

    query_message = """select * from server_messages where server_ip=%s and message=%s  and status != "complete"  """
    cursor.execute(query_message, message_data)
    query_message_result = cursor.fetchall()
    if (query_message_result == None or (len(query_message_result) == 0)):
        message_data = [server_id, "0", start_map, "pending"]
        insert_message = """ insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s)  """
        cursor.execute(insert_message, message_data)
        connection.commit()
        return "added server for spinup"
    else:
        connection.commit()
        return "already has instance waiting for spinup..."


def admin_ui_command(connection, cursor, command, server_id):
    if command == "ForceUpdate":
        message_data = [server_id, command]

        query_message = """select * from server_messages where server_ip=%s and message=%s  and status != "complete"  """
        cursor.execute(query_message, message_data)
        query_message_result = cursor.fetchall()
        if (query_message_result == None or (len(query_message_result) == 0)):
            message_data = [server_id, "0", command, "pending"]
            insert_message = """ insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s)  """
            cursor.execute(insert_message, message_data)
            connection.commit()
            return "Server added for force update"

    if command == "RestartServer":
        message_data = [server_id, command]

        query_message = """select * from server_messages where server_ip=%s and message=%s  and status != "complete"  """
        cursor.execute(query_message, message_data)
        query_message_result = cursor.fetchall()
        if (query_message_result == None or (len(query_message_result) == 0)):
            message_data = [server_id, "0", command, "pending"]
            insert_message = """ insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s)  """
            cursor.execute(insert_message, message_data)
            connection.commit()
            return "Server added for restart"

    if command == "StopServer":
        message_data = [server_id, command]

        query_message = """select * from server_messages where server_ip=%s and message=%s  and status != "complete"  """
        cursor.execute(query_message, message_data)
        query_message_result = cursor.fetchall()
        if (query_message_result == None or (len(query_message_result) == 0)):
            message_data = [server_id, "0", command, "pending"]
            insert_message = """ insert into server_messages (server_ip,server_port,message,status) values (%s,%s,%s,%s)  """
            cursor.execute(insert_message, message_data)
            connection.commit()
            return "Server added for stop"


''' server_query = [server_id]
fetch_server = """select * from servers where id=%s """
cursor.execute(fetch_server, server_query)
fetch_server_result = cursor.fetchone()
connection.commit()

if fetch_server_result == None or (len(fetch_server_result) == 0):
    return ("there is no servers with this id")
else:
    id = fetch_server_result[0]
    status = ["complete", requested_server, id]
    update_map_request = """ update waiting_instances set status=%s,server_requested=%s where id=%s """
    cursor.execute(update_map_request, status)
    connection.commit()

    create(connection, cursor, requested_server, map_name, port)
    # status = [requested_server,map_name,port]
    # update_map_request = """ insert into servers (server_ip, map_name,port) values (%s,%s,%s) """
    # cursor.execute(update_map_request, status)
    return "success"
    '''
