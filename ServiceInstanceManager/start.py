import sys
import os
import config
import requests
import subprocess
import time

## config file defs

onload_map_start = config.onload_map_start
onload_map = config.onload_map
Starting_Port = str(config.Starting_Port)
current_directory = os.getcwd()
url = "http://"+config.Domain+":"+config.Port+"/"
args = False
command = ""
execute = ""
id = ""


def create_session(start_on_load = None, Map = None):
    ### lets see if there is any instances running
    command = '''screen -ls | grep "ServerInstance"| awk '{print $1}' | cut -d. -f 2 '''  # the shell command to list screen processes
    process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)

    # Launch the shell command:
    output = process.communicate()
    screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
    screens_list = screens.split()

    if (len(screens_list) > 0):
        # print(screens_list)
        session_id = 0
        for x in screens_list:
            current_session_id = int(x[-4:])
            print(current_session_id)
            if (current_session_id >= session_id):
                session_id = current_session_id

        new_session = str(session_id + 1)
        start_map = "screen -S ServerInstance-" + onload_map + "-" + new_session + " -d -m /usr/bin/python3 " + current_directory + "/instance_starter.py " + new_session + " " + onload_map
        os.system(start_map)
        print("Map: " + onload_map + " Started on port: " + new_session)

        #requests.get(url+"")

    else:
        if start_on_load:
            start_map = "screen -S ServerInstance-"+onload_map+"-"+Starting_Port+" -d -m /usr/bin/python3 "+current_directory+"/instance_starter.py "+Starting_Port+" "+onload_map
            os.system(start_map)
            print("Map: " + onload_map + " Started on port: " + Starting_Port)

        else:
            if Map:
                new_session = str(config.Starting_Port)
                start_map = "screen -S ServerInstance-" + Map + "-" + new_session + " -d -m /usr/bin/python3 " + current_directory + "/instance_starter.py " + new_session + " " + Map
                print(start_map)
                os.system(start_map)
                print("Map: " + onload_map + " Started on port: " + new_session)
                print("i am trgiggering this")
            else:
                print("i cannot do this action i am sorry")


#### check if any args are passed, if args passed do x with arg

## take arguments to start program
input = sys.argv[1:]


## check if we have all params and set params
if(len(input) >= 1):
   # print("args recieved")
    args = True

    if(input[0] == "kill"):
        if(len(input[1]) > 0):
            command = "kill"
            execute = input[1]
        else:
            print("you need to supply command option")

    if (input[0] == "start"):
        command = "start"
    if(input[0] == "startmap"):
        if(len(input[1]) > 0):
            command = "startmap"
            execute = input[1]
        else:
            print("you need to give us a map to start...")

    if(input[0] == "killall"):
        command = "killall"
    if(input[0] == "ls"):
        command = "ls"
    if (input[0] == "lsp"):
        command = "lsp"
    if (input[0] == "help"):
        command = "help"
    if (input[0] == "delete"):
        command = "delete"
        execute = input[1]
        id = input[2]



else:
    print("no args passed doing normal startup")

print("i am args")
print(args)
if args:
    if(command == "help"):
        print("  __________________________________________________________")
        print(" |           Welcome To v0dka Server Instance Manager      |")
        print(" |                   the options are                       |")
        print(" |       kill servername - kills the given servername      |")
        print(" |       killall - kills all servers                       |")
        print(" |       ls -  list all servers                            |")
        print(" |       lsp - list all servers + ports used + process id  |")
        print(" |_________________________________________________________|")
    if(command == "kill"):
        command = ''' screen -ls | grep "ServerInstance"| awk '{print $1}' '''  # the shell command to list screen processes
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
        output = process.communicate()
        screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
        kill_screens_list = screens.split()
        print(kill_screens_list)
        found_kill_screen = False
        for x in kill_screens_list:
            res = x.split(".")
            if execute in res[1]:
                found_kill_screen = True
                print("server instance found, now killing server instance")
                command_kill = 'screen -XS '+res[0]+' quit'  # the shell command to list screen processes
                os.system(command_kill)
                break



        if found_kill_screen:
            print("killed server instance :) ")
        else:
            print("cannot find server instance")



    if(command == "killall"):

        x = requests.get("http://" + config.Domain + ":" + config.Port + "/deleteconsolerequest")
        if x.content.decode("utf-8") == "success":
            print("killed all server instances")
            os.system("killall screen")
        else:
            print(x.content.decode("utf-8"))
    if(command == "ls"):
        command = '''screen -ls | grep "ServerInstance"| awk '{print $1}' | cut -d. -f 2 '''  # the shell command to list screen processes
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
        output = process.communicate()
        screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
        screens_list = screens.split()
        print("Listing Servers: \n")
        for x in screens_list:
            print(x+"\n")
        print("all active servers listed")

    if(command == "lsp"):
        print("listing all servers and ports currently active")
        command = '''sudo lsof -iUDP -P -n | grep OpenWorld '''  # the shell command to list screen processes
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
        output = process.communicate()
        screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
        screens_list = screens.split()
        print("Listing Servers: \n")
        print("name      | pid | user | fd | type | node |            |port ")
        print(screens)
    if(command == "startmap"):
        if (len(execute) > 0):
            print("i am here")
            ### lets see if there is any instances running
            command = '''screen -ls | grep "ServerInstance"| awk '{print $1}' | cut -d. -f 2 '''  # the shell command to list screen processes
            process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)

            # Launch the shell command:
            output = process.communicate()
            screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
            screens_list = screens.split()

            if (len(screens_list) > 0):
                session_id = 0
                for x in screens_list:
                    current_session_id = int(x[-4:])
                    if (current_session_id >= session_id):
                        session_id = current_session_id

                new_session = str(session_id + 1)
                print(new_session)
                start_map = "screen -S ServerInstance-"+execute+"-" + new_session + " -d -m /usr/bin/python3 " + current_directory + "/instance_starter.py " + new_session + " " + execute
                print(start_map)
                os.system(start_map)
                print("Map: " + execute + " Started on port: " + new_session)
            else:
                create_session(None, execute)
        else:
            print("need to add paramater for map")
    if(command == "start"):
        print("i am here")
        ### lets check if the server instancer is already running...
        command = '''screen -ls | grep "ServerInstanceManager"| awk '{print $1}' | cut -d. -f 2 '''  # the shell command to list screen processes
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
        # Launch the shell command:
        output = process.communicate()
        screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
        screens_list = screens.split()

        if (len(screens_list) == 0):
            print("i made it here")
            start_manager = "screen -S ServerInstanceManager -d -m /usr/bin/python3 " + current_directory + "/instance_manager.py"
            os.system(start_manager)
    if(command == "delete"):
        ### lets check if the server instancer is already running...
        command = '''screen -ls | grep "'''+execute+'''"| awk '{print $1}' | cut -d. -f 2 '''  # the shell command to list screen processes
        process = subprocess.Popen(command, stdout=subprocess.PIPE, stderr=None, shell=True)
        # Launch the shell command:
        output = process.communicate()
        screens = output[0].decode("utf-8")  ## because it returns in bytes we need to decode to text
        screens_list = screens.split()
        print("im here")
        print(len(screens_list))
        print(screens_list)
        print(execute)
        print(id)

        if (len(screens_list) != 0):
            print("i am killing")
            command_kill = 'screen -XS ' + screens_list[0] + ' quit'  # the shell command to list screen processes
            os.system(command_kill)
            requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + str(id))



if not args:
    print("starting with no args")
    create_session(True,None)


### main loop





#killall screen

#test = "testing (12/01/22 18:08:00)     (Detached)"


#results = os.popen('./test.sh')
#print(results.read())

#os.system('screen -ls | grep "testing"| cut -d. -f 2')
#os.system("screen -S ServerInstance-1 -d -m /usr/bin/python3 /home/debian/abc.py")


#results = subprocess.check_output(['./test.sh'])
#print(results)

#os.system('screen -ls | grep "testing"| awk "{print $1}" | cut -d. -f 2')
#os.system("screen -S ServerInstance-1 -d -m /usr/bin/python3 /home/debian/abc.py")
#remove = " "
#a = test.split(remove,1)[0]
#print(a)