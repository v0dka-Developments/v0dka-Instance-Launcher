Max_Players = 64
Dedicated_Server_Folder = "~/current_game_build/"
Dedicated_Server_Location = "/home/debian/current_game_build/my_game_server.sh" ## this will be updated via python script so dont worry about it too much :D
Domain = "51.38.81.172"  # enter domain or ip here of api
Port = "8090"
Starting_Port = 7777  # default port to start on
Max_Instances = 5  # max number of instances on this server
steam = False  # use steam or not
log = True  # logging

## this is only for startup map so if this server script is running on this script will load initial map so players
## dont need to wait on map spinups

onload_map_start = False
onload_map = "ThirdPersonExampleMap"

## this must be same as server instance api key for this to be added to database...
ServerAddSecretKey = "IamASecretKeyWooo!"
