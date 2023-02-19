import sys
import os
import config
import requests
import subprocess
import time
from pathlib import Path
import zipfile
import io

current_directory = os.getcwd()

## lets tell our api we exist...

url = "http://" + config.Domain + ":" + config.Port + "/add_dedicated_server"
data_for_post = {"secret_key": config.ServerAddSecretKey}
f = requests.post(url, json=data_for_post)
print(f.content.decode("utf-8"))


## download function
def download_zip(unzip_path, override=None):
    request_server_build = requests.get("http://" + config.Domain + ":" + config.Port + "/download_update")
    # if reponse is less than 30 bytes we know that the response is not to download file
    if len(request_server_build.content) < 30:
        return ("there is no server build to download... upload a server build...")
    else:
        ## check if we have a zip file already
        ## set file
        build_zip = Path(os.path.expanduser(current_directory + "/game_build.zip"))
        if build_zip.is_file():
            ## get size of build file
            size_of_build = Path(current_directory + "/game_build.zip").stat().st_size
            # check size of build file is not the same as content if same as content then no need to download because its the same....
            # i should maybe do some file hasing for this in future but this works for now...
            if size_of_build < len(request_server_build.content) or override:
                print("downloading file...")
                unzip = zipfile.ZipFile(io.BytesIO(request_server_build.content))
                with open(build_zip, 'wb') as out:
                    out.write(request_server_build.content)
                unzip.extractall(unzip_path)
                if not override:
                    return "download of file has complete and has been unzipped to game build directory"
                else:
                    return "do request"
            else:
                return "no need to download file it is same size"
        else:
            print("i do not have zip file so must make")
            os.system("touch " + current_directory + "/game_build.zip")
            print("file created")
            print("downloading file...")
            unzip = zipfile.ZipFile(io.BytesIO(request_server_build.content))
            with open(build_zip, 'wb') as out:
                out.write(request_server_build.content)

            unzip.extractall(unzip_path)
            sh_file_path = next(Path(unzip_path).glob('**/*.[sS][hH]'))
            print(str(sh_file_path))
            config_file_path = current_directory+"/config.py"
            ## update config file to represent the sh name to execute from the zip file...
            with open(config_file_path, "r+") as config_file:
                # read the contents of the file
                contents = config_file.read()

                # find the Dedicated_Server_Location line
                dedicated_server_location_line = \
                [line for line in contents.split("\n") if "Dedicated_Server_Location" in line][0]

                # replace the old value with the new value
                new_contents = contents.replace(dedicated_server_location_line,
                                                f'Dedicated_Server_Location = "{sh_file_path}"')

                # move the file pointer back to the beginning of the file
                config_file.seek(0)

                # overwrite the file with the new contents
                config_file.write(new_contents)

                # truncate the file in case the new contents are shorter than the old contents
                config_file.truncate()


            ## update variable for this time running
            config.Dedicated_Server_Location = sh_file_path
            return "download of file has complete and has been unzipped to game build directory"


## check if we have a server build
build_file = Path(os.path.expanduser(config.Dedicated_Server_Location))
build_directory = Path(os.path.expanduser(config.Dedicated_Server_Folder))
### first run we check if we have a server build directory and a server build, if not directory create if not file request file from api...
if not build_file.is_file():
    print("i am not a build file so i am checking")
    if not build_directory.is_dir():
        print("i am not a directory creating")
        os.makedirs(build_directory)
        print("i am downloading zip and making build")
        res = download_zip(build_directory, None)
        print(res)
    else:
        print("downloading zip and extract")
        ## need to get the server build to download :|
        res = download_zip(build_directory,None)
        print(res)
else:
    res = download_zip(build_directory,None)
    print(res)

while True:
    try:
        x = requests.get("http://" + config.Domain + ":" + config.Port + "/spin_me_up")
        z = requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=&id=")
        result = x.text
        message = z.text
        print(message)
        if result == "no instances to create":
            print("no instances")

        else:
            print("must create server" + result)
            start_map = "/usr/bin/python3 " + current_directory + "/start.py startmap " + result
            os.system(start_map)

        if "delete" in message:
            print("i should delete server")
            server_message = message.split()
            kill_session = "/usr/bin/python3 " + current_directory + "/start.py delete " + server_message[2] + " " + \
                           server_message[0]
            os.system(kill_session)
            requests.get(
                "http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[1])

        if "start:" in message:
            server_message = message.split()
            get_map_to_start = server_message[1].split(":")
            print("i should start map "+ get_map_to_start[1])
            start_map = "/usr/bin/python3 " + current_directory + "/start.py startmap " + get_map_to_start[1]
            os.system(start_map)
            requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])


        if "ForceUpdate" in message:
            server_message = message.split()

          ## must add force update stuff shutdown all servers and download new update...
            print("Killing all local unreal engine server instances")
            start_map = "/usr/bin/python3 " + current_directory + "/start.py killall"
            os.system(start_map)
            time.sleep(10)
            print("i am now doing update")
            res = download_zip(build_directory, True)
            if res == "do request":
                requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])
                print("force updated successfully")
            else:
                print("fucked")
                print(res)


        if "RestartServer" in message:
            server_message = message.split()
            print("restarting server")
            requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])
            os.system("sudo reboot")


        if "StopServer" in message:
            # requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])
            # os.system("init 0")
            print("stopping server")

        ## because i am lazy and conflict in word restart and start i use reload so we dont have issue maybe i fix in future when i am not so lazy
        if "reload:" in message:

            server_message = message.split()

            server_map = server_message[1].split(":")

            server_port = server_message[2]
            kill_message = server_map[1]+"-"+server_port
            print("reloading server"+kill_message)
            start_map = "/usr/bin/python3 " + current_directory + "/start.py kill " + kill_message
            os.system(start_map)
            requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])
            ### need to add restart on port to start.py when i have time...


        if "stop:" in message:
            server_message = message.split()

            server_map = server_message[1].split(":")

            server_port = server_message[2]
            kill_message = server_map[1] + "-" + server_port
            print("stopping server" + kill_message)
            start_map = "/usr/bin/python3 " + current_directory + "/start.py kill " + kill_message
            os.system(start_map)
            requests.get("http://" + config.Domain + ":" + config.Port + "/status?status=complete&id=" + server_message[0])




        time.sleep(10)
    except:
        print("cant connect to api on ip", config.Domain, " and port ", config.Port, " trying again in 10 seconds")
        time.sleep(10)
