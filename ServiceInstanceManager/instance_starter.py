import sys
import os
import config

## config options
Max_Players = config.Max_Players
Dedicated_Server_Location = config.Dedicated_Server_Location
Starting_Port = str(config.Starting_Port)
Max_Instances = config.Max_Instances
steam = config.steam
log = config.log

## take arguments to start program
input = sys.argv[1:]
can_start_port = False
can_start_map = False
map_to_start = ""
port_to_start = ""
## check if we have all params and set params
if(len(input) >= 2):
    if(input[0].isdigit()):
       print("port number is success")
       can_start_port = True
       port_to_start = input[0]
    else:
        print("this must be a valid port number")
    if(input[1].isdigit()):
       print("map name must not be port number")
    else:
       can_start_map = True
       map_to_start = input[1]
       print("map name is success")

else:
    print("you need to give all params, usage script.py port map")


if(can_start_map and can_start_port):
    path_param = Dedicated_Server_Location + " " + map_to_start + "?listen -server -log -port=" + port_to_start
    print("i am executing this"+path_param)
    os.system(path_param)


input = sys.argv[1:]

print(input)
if(len(sys.argv) >= 2):
    print("succes")
else:
    print("need all data")

if(len(input[0]) == 0):
    print("you must give a port number")
if(len(input[1]) == 0):
    print("you must give a map name")
port = input[0]
map = input[1]

#print(Max_Players,Dedicated_Server_Location,Starting_Port,Max_Instances,steam,log,onload_map_start,onload_map)

#PackagedServer.exe MapName?listen -server -log -nosteam -port=7778

#if (onload_map_start == True):
#    path_param = Dedicated_Server_Location+" "+onload_map+"?listen -server -log -port="+Starting_Port
#    print(path_param)
#    os.system(path_param)



#while True:
#    print("hello")




