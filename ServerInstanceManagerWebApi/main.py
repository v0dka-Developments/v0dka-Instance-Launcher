from flask import Flask, request, send_file, render_template, redirect, url_for, session, flash
import mysql.connector
from mysql.connector import Error
import server
import config
from werkzeug.utils import secure_filename
import os
from pathlib import Path

current_directory = os.getcwd()
UPLOAD_FOLDER = current_directory + "/" + config.Folder + "/"
ALLOWED_EXTENSIONS = {'zip'}

app = Flask(__name__)
app.static_folder = 'static'
app.secret_key = config.AppSecretKey
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
connection = ""
cursor = ""

# function for checking allowed file types for upload in admin panel
def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS


# Это пути приложения к которым пользователь будет иметь доступ.

# user routes for application path if user access http://ip:port/create it does logic for the /create path etc..

@app.route("/")
def index():
    return "version 1.0"


@app.route("/create")
def create():
    args = request.args
    server_ip = args['ip']
    map_name = args['map']
    port = args['port']
    return server.create(connection, cursor, server_ip, map_name, port)


@app.route("/delete")
def delete():
    args = request.args
    server_ip = args['ip']
    map_name = args['map']
    port = args['port']
    return server.delete(connection, cursor, server_ip, port)


@app.route("/masterdelete")
def master_delete():
    args = request.args
    password = args['password']

    return server.master_delete(connection, cursor, password)


@app.route("/deleteconsolerequest")
def delete_all_console():
    ip = request.remote_addr
    return server.delete_all_console(connection, cursor, ip)


@app.route("/updateplayers")
def update_players():
    args = request.args
    player_count = args['players']
    server_ip = request.remote_addr
    map_name = args['map']
    port = args['port']

    return server.update_players(connection, cursor, server_ip, map_name, port, player_count)


@app.route("/request_player_server")
def request_player_server():
    args = request.args
    map_name = args['map_name']
    return server.request_player_server(connection, cursor, map_name)


@app.route("/spin_me_up")
def spin_up_server():
    return server.spin_up_server(connection, cursor, request.remote_addr)


@app.route("/spin_up_complete")
def spin_up_complete():
    args = request.args
    port = args['port']
    map_name = args['map_name']
    return server.spin_up_complete(connection, cursor, request.remote_addr, port, map_name)


@app.route("/status")
def status():
    args = request.args
    ip = request.remote_addr
    message = args['status']
    id = args["id"]
    return server.status(connection, cursor, ip, message, id)


@app.route("/check_for_zero")
def check_for_zero():

    #ip = request.remote_addr
    args = request.args
    ip = args["ip"]

    return server.check_for_zero(connection,cursor,ip)


@app.route("/download_update")
def download_update():
    result = server.download_update()
    validate_is_file = Path(result)

    if validate_is_file.is_file():
        return send_file(result, as_attachment=True)
    else:
        return "nothing to send"


@app.route("/add_dedicated_server", methods=['GET', 'POST'])
def add_dedicated_server():
    ip = request.remote_addr
    if request.method == 'POST':

        secret_key = request.json['secret_key']
        if secret_key == config.ServerAddSecretKey:
            return server.add_dedicated_server(connection, cursor, ip)
        else:
            return "error"
    else:
        return "error"

@app.route("/priv_key")
def priv_key():
    args = request.args
    password = args['password']

    if password == config.Master_Password:
        return config.ServerAddSecretKey


'''
##########################################################################################################################################


                                                    all admin UI app routes


##########################################################################################################################################
'''


@app.route("/control_me", methods=['GET', 'POST'])
def control_me():
    error = None
    if request.method == 'POST':
        if request.form['username'] != 'admin' or request.form['password'] != config.Master_Password:
            error = 'Invalid Credentials. Please try again.'
        else:
            session['logged_in'] = True
            return redirect(url_for('dashboard'))
    return render_template('login.html', error=error)


@app.route("/dashboard")
def dashboard():
    if 'logged_in' in session and session['logged_in']:
        return render_template("dashboard.html")
    else:
        return redirect(url_for('control_me'))


@app.route("/upload_build", methods=['GET', 'POST'])
def upload_build():
    if 'logged_in' in session and session['logged_in']:
        if request.method == "POST":
            if 'file' not in request.files:
                flash("failed select file please")
                return redirect(request.url)
            file = request.files['file']
            if file.filename == '':
                flash("failed select file please")
                return redirect(request.url)
            if file and allowed_file(file.filename):
                filename = secure_filename(file.filename)
                file.save(os.path.join(app.config['UPLOAD_FOLDER'], filename))
                flash("success")
                return redirect(request.url)
            else:
                flash("sorry this file could not be allowed for upload")
                return redirect(request.url)

        else:
            return render_template("upload_build.html")
    else:
        return redirect(url_for('control_me'))


@app.route("/server_list", methods=['GET', 'POST'])
def server_list():
    if 'logged_in' in session and session['logged_in']:

        fetch_server = """select * from servers"""
        cursor.execute(fetch_server)
        fetch_server_result = cursor.fetchall()
        connection.commit()

        if fetch_server_result == None or (len(fetch_server_result) == 0):
            servers = []
        else:
            servers = fetch_server_result

        if request.method == "POST":
            update = request.form.get("update")
            server_id = request.form.get("server_id")
            force_update = request.form.get("force_update")
            force_restart = request.form.get("force_restart")
            stop_server = request.form.get("stop_server")

            if update:
                flash("I am now shutting servers down and updating...")
                res = server.admin_ui_server_manager(connection, cursor, server_id, "update_all")
                flash(res)

            if server_id:


                if force_restart:
                    res = server.admin_ui_server_manager(connection, cursor, server_id, "force_restart")
                    flash(res)
                if stop_server:
                    res = server.admin_ui_server_manager(connection, cursor, server_id, "stop_server")
                    flash(res)

            return render_template("server_list.html", servers=servers)
        return render_template("server_list.html", servers=servers)
    else:
        return redirect(url_for('control_me'))


@app.route("/dedicated_server_list", methods=['GET', 'POST'])
def dedicated_server_list():
    if 'logged_in' in session and session['logged_in']:

        fetch_server = """select * from dedicated_servers"""
        cursor.execute(fetch_server)
        fetch_server_result = cursor.fetchall()
        connection.commit()

        if fetch_server_result == None or (len(fetch_server_result) == 0):
            servers = []
        else:
            servers = fetch_server_result

        if request.method == "POST":
            if request.form.get("MapName") and request.form.get("Server_IP"):
                map_name = request.form.get("MapName")
                server_id = request.form.get("Server_IP")
                res = server.admin_ui_start_map(connection, cursor, map_name, server_id)
                flash(res)
            if request.form.get("ForceUpdate") and request.form.get("Server_IP"):
                command = "ForceUpdate"
                res = server.admin_ui_command(connection, cursor, command, request.form.get("Server_IP"))
                flash(res)
            if request.form.get("RestartServer") and request.form.get("Server_IP"):
                command = "RestartServer"
                res = server.admin_ui_command(connection, cursor, command, request.form.get("Server_IP"))
                flash(res)
            if request.form.get("StopServer") and request.form.get("Server_IP"):
                command = "StopServer"
                res = server.admin_ui_command(connection, cursor, command, request.form.get("Server_IP"))
                flash(res)

            return render_template("dedicated_server_list.html", servers=servers)
        return render_template("dedicated_server_list.html", servers=servers)
    else:
        return redirect(url_for('control_me'))


@app.route("/logout")
def logout():
    session.pop('logged_in', None)
    return redirect(url_for("control_me"))


if __name__ == "__main__":

    start_message = '''
        
        \x1b[6;30;42m############################################################################\x1b[0m
        \x1b[6;30;42m#                       V0dka Instance Launcher API                        #\x1b[0m
        \x1b[6;30;42m#                                Version 1.0.0                             #\x1b[0m
        \x1b[6;30;42m############################################################################\x1b[0m
        
    '''

    print(start_message)

    build_directory = Path(current_directory + "/" + config.Folder)
    if not build_directory.is_dir():
        print('\033[91m' + "download directory does not exist creating directory" + '\033[0m')
        os.mkdir(build_directory)

    try:
        connection = mysql.connector.connect(host=config.Host, database=config.Database, user=config.Username,
                                             password=config.Password)
        cursor = connection.cursor(prepared=True)
        if connection.is_connected():
            print("database connection established")
            app.run(host=config.IP, port=config.Port, debug=config.Debug)
    except Error as e:
        print("Error while connecting to MySQL", e)
