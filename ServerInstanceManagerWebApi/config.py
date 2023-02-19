Master_Password = "hello"
Max_Players = 64
Soft_Cap = 10
zero_timer = 10 # time in minutes if server empty will close server so if value 10 after 10 minutes of zero player server close

### web server connection

AppSecretKey = "askdlmacsducASDaksmd123109CAmlkasdasdQ:asdadCAScasl;asd"  ## setup a secure private key for storing session data
IP = ""
Port = 8090
Debug = True  ### set this to false on live env because running debug is danger

### mysql connection
Host = ""
Database = "vodkainstancemanager"
Username = ""
Password = ""

### updates
Folder = "game_build"  ## folder name of where you upload your build

### this is the secret key to allow servers to be added to the database make sure this matches with your ServiceInstance key
ServerAddSecretKey = "IamASecretKeyWooo!"
