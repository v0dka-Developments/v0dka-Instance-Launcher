#!/bin/bash

## colors moved to begining of script so error can be printed before script execution
## colours
# function to print text in red color
function print_red {
    echo -e "\033[31m$1\033[0m"
}

function print_green {
    echo -e "\033[32m$1\033[0m"
}


function print {
    echo -e "\033[38;5;208m$1\033[0m"
}


## 09/12/2024
## added error handling before script starts
if [[ -z "$1" ]]; then
    print_red "No parameters passed usage install.sh full or install.sh api or install.sh launcher, you can now pass localdev as an extra paramater"
    exit 1
fi

sudo apt update && sudo apt upgrade -y
## we require these for packages to install them before we continue
sudo apt-get install gcc openssl -y
# 09/12/2024 -> curl install
#some distros are not pre-installed with curl lets make sure we have it

sudo apt-get install curl



### logo :D
logo(){
echo '             ..::-++**=:.'
echo '           =******************+'
echo '          +******#%%#*********+'
echo '        .+*********************.'
echo '     .:-****************#####-='
echo '   =***#******************###-'
echo '   =*###********************-'
echo '    :=*********************+'
echo '      :********************=              ..:.'
echo '      =********************+         .:=+****+      '
echo '     -**********************.    .:=********+. '
echo '     +**********************- .:+**********= '
echo '    =************************+***********=:'
echo '   .***********************************=.'
echo '   =*********************************+:'
echo -e '   +********************************=          \x1B[32m         __   __                       __  ___            __   ___                         __        ___  __\033[0m '
echo -e '   =*******************************-           \x1B[32m   \  / /  \ |  \ |__/  /\     | |\ | /__`  |   /\  |\ | /  ` |__     |     /\  |  | |\ | /  ` |__| |__  |__) \033[0m'
echo -e '   -******************************+.            \x1B[32m   \/  \__/ |__/ |  \ /~~\    | | \| .__/  |  /~~\ | \| \__, |___    |___ /~~\ \__/ | \| \__, |  | |___ |  \ \033[0m'
echo '   -**************************###***-'
echo '   -************************#%%#******+++++****+-.'
echo '   =**********************###**%#*****************='
echo '  .********************####****#%******************+'
echo '  =*******************##********%*******************-'
echo ' .+*****************************##**********=:::=***='
echo ' -*******************************#******=:.       '
echo ' +********************************+=::.'
echo '.*********************************=.'
echo '-***********************************-.'
echo '=*************************************=:'
echo '=***************************************+-.'
echo '+******************************************=:'
echo '+************************************#*******=:'
echo '+***********************************##*********=.'
echo '+**###%##**************************#@************-'
echo '+******#####***********************%#************+.'
echo '=***********#*********************#%**************+'
echo '=********************************#%****************-'
echo '-*******************************##*****************+:'
echo '.+*****************************##**********************=:'
echo '  :=**************************#*********++++==+***********='
echo '     :=********************=:::::...           .:=+****++=:'
echo '        :-**************+.'
echo '           .:=***********:'
echo '               :=*******+.'
}

logo



### not for self use masterpassword auth for getting server add secret key



### global vars 
export MYSQL_PASSWORD="$(openssl rand -hex 20)"
export MYSQL_PASSWORD_USER="$(openssl rand -hex 20)"
export MYSQL_NEW_USER="vodka_instance"
export APP_SECRET_KEY="$(openssl rand -hex 40)"
export API_LOGIN_PASSWORD="$(openssl rand -hex 20)"
export SERVER_ADD_SECRET_KEY="$(openssl rand -hex 30)"
export IP=$(curl -s ifconfig.me)


## 09/12/2024
## added for local testing this will pull the local networks ip rather than wan network ip
## so ip will return 10.x or 192.x depending on your networking setup... rather than the global ip
if [[ "$2" == "localdev" ]]; then
    #lip = local ip
    lip=$(ip addr show | awk '/inet / && $NF != "lo" {print $2}' | cut -d/ -f1 | head -n 1)
    echo "Debug: Retrieved IP: $lip"
    echo "$lip"
    export IP=$lip
    if [[ -z "$IP" ]]; then
        echo "Failed to retrieve local IP address. Ensure the network interface is up." >&2
        exit 1
    fi
    echo "Using local IP: $IP"
fi


### functions


update_upgrade(){

  print_green "updating packages"
  sudo apt update && sudo apt upgrade -y


}



### check python install
verify_python(){

    python=$(python --version)
    python3=$(python3 --version)

    #echo $python
    #echo $python3
    if echo "$python" | grep -q "Python 3" || echo "$python3" | grep -q "Python 3";
    then
        print_green "Python 3 is installed"
    else
        ### if people really request python to be included in the auto installer ill add it but for now just error out and tell them python is not installed
        print_red "error: python not installed, please install python to your system" >&2; exit 1
    fi
}

## check pip install
verify_pip(){

  pip=$(pip --version)

  if echo "$pip" | grep -q "pip"
  then
    print_green "pip is installed"
  else
    print_red "pip is not installed i am now installing pip"
    sudo apt-get install python3-pip -y
  fi


}
## install the packages we need for the launcher/api
install_linux_packages(){

  update_upgrade
  sudo apt install screen lsof systemd wget git -y



}


install_mysql(){


  
  echo "The current user is: $USER"

  ## updated to latest mysql config 09/12/2024
  cd ~/ && wget https://dev.mysql.com/get/mysql-apt-config_0.8.30-1_all.deb
  
  ## generate random secure password

# set some config to avoid prompting
sudo debconf-set-selections <<EOF
mysql-apt-config mysql-apt-config/select-server select mysql-8.0
mysql-community-server mysql-community-server/root-pass password $MYSQL_PASSWORD
mysql-community-server mysql-community-server/re-root-pass password $MYSQL_PASSWORD
EOF

# set debian frontend to not prompt
export DEBIAN_FRONTEND="noninteractive";

# config the package
sudo -E dpkg -i ./mysql-apt-config_*_all.deb;

# update apt to get mysql repository
sudo apt-get update

# create the MySQL configuration file to set the root password
sudo sh -c "echo '[client]' > /etc/mysql/conf.d/mysql_config.cnf"
sudo sh -c "echo 'user=root' >> /etc/mysql/conf.d/mysql_config.cnf"
sudo sh -c "echo 'password=$MYSQL_PASSWORD' >> /etc/mysql/conf.d/mysql_config.cnf"

# install mysql-server with the MySQL configuration file and no recommended packages
sudo -E apt-get install mysql-server --assume-yes --no-install-recommends

 
  sudo systemctl enable --now mysql
  

  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print_red "              your root user is root                          "
  print_red "              your root password is $MYSQL_PASSWORD           "
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"

  print_red " now performing secure install and creating addditional user"

 sudo mysql -u root -p$MYSQL_PASSWORD -e "UPDATE mysql.user SET Password=PASSWORD('$MYSQL_PASSWORD') WHERE User='root';"
 sudo mysql -u root -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
 sudo mysql -u root -p$MYSQL_PASSWORD -e "DELETE FROM mysql.user WHERE User='';"
 sudo mysql -u root -p$MYSQL_PASSWORD -e "DROP DATABASE test;"
 sudo mysql -u root -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

print " Secure install now complete, i now creating new user and password"

sudo mysql -u root -p$MYSQL_PASSWORD -e "CREATE USER '$MYSQL_NEW_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD_USER';"
sudo mysql -u root -p$MYSQL_PASSWORD -e "CREATE USER '$MYSQL_NEW_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD_USER';"
sudo mysql -u root -p$MYSQL_PASSWORD -e "GRANT ALL ON *.* TO '$MYSQL_NEW_USER'@'localhost';"
sudo mysql -u root -p$MYSQL_PASSWORD -e "GRANT ALL ON *.* TO '$MYSQL_NEW_USER'@'%';"
sudo mysql -u root -p$MYSQL_PASSWORD -e "FLUSH PRIVILEGES;"

  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print_red "        your account to user is $MYSQL_NEW_USER           "
  print_red "        your password is $MYSQL_PASSWORD_USER"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  print "##############################################################"
  
  print "new user is added i am now creating the database"
  


  wget https://raw.githubusercontent.com/v0dka-Developments/v0dka-Instance-Launcher/main/database/current.sql

  mysql -u vodka_instance -p$MYSQL_PASSWORD_USER < ~/current.sql

  print "database has now been created"

}


install_full(){

  print "_____________________________________"
  print "|  now installing the full launcher! |"
  print "______________________________________"


  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  rm -rf ./database # we dont need this directory as we already installed db from raw github output
  CURRENT_DIR=$(pwd)
  CURRENT_USER=$(whoami)
  CURRENT_HOME=$(eval echo ~$CURRENT_USER)
  ## lets update the api configs first

  sed -i "s/Master_Password = \".*\"/Master_Password = \"$API_LOGIN_PASSWORD\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/AppSecretKey = \".*\"/AppSecretKey = \"$APP_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/IP = \".*\"/IP = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Debug = .*$/Debug = False/' ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Host = \".*\"/Host = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Database = ".*"/Database = "vodkainstancemanager"/' ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Username = \".*\"/Username = \"$MYSQL_NEW_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/\bPassword = \".*\"/Password = \"$MYSQL_PASSWORD_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py


  # now lets configure the service file cheat way lets just regex for username and replace for current logged in user...
  #sed -i "s/username/$USER/g" ./ServerInstanceManagerWebApi/vodka_api.service
  # Update the service file with the correct paths, user, and environment
  sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $CURRENT_DIR/ServerInstanceManagerWebApi/main.py|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR/ServerInstanceManagerWebApi|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|Environment=.*|Environment=\"PATH=$CURRENT_HOME/.local/bin:\$PATH\"|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s/User=.*/User=$CURRENT_USER/" ./ServerInstanceManagerWebApi/vodka_api.service

  ### ok now we have configured everything lets pip install the requirements
  ## update 09/12/2024 -> install pip packages as system wide, maybe make this env in future if people running
  # multiple different depenancies as this would cause a depeancy clash if versions are miss match
  pip install --break-system-packages -r ./ServerInstanceManagerWebApi/requirements.txt 

  ## now lets copy the service file to systemd
  sudo cp ./ServerInstanceManagerWebApi/vodka_api.service /etc/systemd/system/vodka_api.service



  ### the api setup should now be complete lets do the launcher
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServiceInstanceManager/config.py
  sed -i "s/Domain = \".*\"/Domain = \"$IP\"/" ./ServiceInstanceManager/config.py
  sed -i 's/\bPort = .*$/Port = "8090"/' ./ServiceInstanceManager/config.py
  ## update the service file...
  #sed -i "s/username/$USER/g" ./ServiceInstanceManager/vodka_manager.service
    # Update the service file with the correct paths, user, and environment
  sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $CURRENT_DIR/ServiceInstanceManager/instance_manager.py|" ./ServiceInstanceManager/vodka_manager.service
  sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR/ServiceInstanceManager|" ./ServiceInstanceManager/vodka_manager.service
  sed -i "s|Environment=.*|Environment=\"PATH=$CURRENT_HOME/.local/bin:\$PATH\"|" ./ServiceInstanceManager/vodka_manager.service
  sed -i "s/User=.*/User=$CURRENT_USER/" ./ServiceInstanceManager/vodka_manager.service
  
  ## copy service to systemd
  sudo cp ./ServiceInstanceManager/vodka_manager.service /etc/systemd/system/vodka_manager.service
  ## install pip requirements
  # update 09/12/2024 -> install pip packages as system wide, maybe make this env in future if people running
  # multiple different depenancies as this would cause a depeancy clash if versions are miss match
  pip install --break-system-packages -r ./ServiceInstanceManager/requirements.txt 


  ## reload systemd
  sudo systemctl daemon-reload
  ## start the services
  sudo systemctl enable vodka_api.service
  sudo systemctl enable vodka_manager.service
  sudo service vodka_api start 
  sudo service vodka_manager start 


}

install_api() {
  echo "_____________________________________"
  echo "|  Now installing the API            |"
  echo "______________________________________"
  
  # Clone the repository
  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  
  # Remove unnecessary directories
  rm -rf ./database # Database already installed
  rm -rf ./ServiceInstanceManager # Launcher is not needed
  
  # Capture the absolute path of the current working directory
  CURRENT_DIR=$(pwd)
  CURRENT_USER=$(whoami)
  CURRENT_HOME=$(eval echo ~$CURRENT_USER)

  # Configure the API configs
  sed -i "s/Master_Password = \".*\"/Master_Password = \"$API_LOGIN_PASSWORD\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/AppSecretKey = \".*\"/AppSecretKey = \"$APP_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/IP = \".*\"/IP = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Debug = .*$/Debug = False/' ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Host = \".*\"/Host = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Database = ".*"/Database = "vodkainstancemanager"/' ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Username = \".*\"/Username = \"$MYSQL_NEW_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/\bPassword = \".*\"/Password = \"$MYSQL_PASSWORD_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py
  
  # Update the service file with the correct paths, user, and environment
  sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $CURRENT_DIR/ServerInstanceManagerWebApi/main.py|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR/ServerInstanceManagerWebApi|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|Environment=.*|Environment=\"PATH=$CURRENT_HOME/.local/bin:\$PATH\"|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s/User=.*/User=$CURRENT_USER/" ./ServerInstanceManagerWebApi/vodka_api.service
  
  # Install pip requirements system-wide
  pip install --break-system-packages -r ./ServerInstanceManagerWebApi/requirements.txt 

  # Copy the service file to systemd and enable the service
  sudo cp ./ServerInstanceManagerWebApi/vodka_api.service /etc/systemd/system/vodka_api.service
  sudo systemctl daemon-reload
  sudo systemctl enable vodka_api.service
  sudo systemctl start vodka_api.service
}


install_launcher(){

  print "_____________________________________"
  print "|  now installing the Launcher       |"
  print "______________________________________"
  KEY=$1
  SERVER_IP=$2
  SERVER_PORT=$3

  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  rm -rf ./database # we dont need this directory as we already installed db from raw github output
  rm -rf ./ServerInstanceManagerWebApi # we only need the instance launcher not the api so lets remove
  CURRENT_DIR=$(pwd)
  CURRENT_USER=$(whoami)
  CURRENT_HOME=$(eval echo ~$CURRENT_USER)


  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$KEY\"/" ./ServiceInstanceManager/config.py
  sed -i "s/Domain = \".*\"/Domain = \"$SERVER_IP\"/" ./ServiceInstanceManager/config.py
  sed -i "s/\bPORT = \".*\"/PORT = \"$SERVER_PORT\"/" ./ServiceInstanceManager/config.py
  ## update the service file...
  #sed -i "s/username/$USER/g" ./ServiceInstanceManager/vodka_manager.service
  # Update the service file with the correct paths, user, and environment
  sed -i "s|ExecStart=.*|ExecStart=/usr/bin/python3 $CURRENT_DIR/ServerInstanceManagerWebApi/main.py|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|WorkingDirectory=.*|WorkingDirectory=$CURRENT_DIR/ServerInstanceManagerWebApi|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s|Environment=.*|Environment=\"PATH=$CURRENT_HOME/.local/bin:\$PATH\"|" ./ServerInstanceManagerWebApi/vodka_api.service
  sed -i "s/User=.*/User=$CURRENT_USER/" ./ServerInstanceManagerWebApi/vodka_api.service
  ## copy service to systemd
  sudo cp ./ServiceInstanceManager/vodka_manager.service /etc/systemd/system/vodka_manager.service
  ## install pip requirements## update 09/12/2024 -> install pip packages as system wide, maybe make this env in future if people running
  # multiple different depenancies as this would cause a depeancy clash if versions are miss match
  pip install --break-system-packages -r ./ServiceInstanceManager/requirements.txt 

  

  ## reload systemd
  sudo systemctl daemon-reload
  ## start the services
  sudo systemctl enable vodka_manager.service
  sudo service vodka_manager start
  

  logo
  print "#################################################################"
  print_green "instance launcher has been installed"
  print "#################################################################"
  print " thank you for using the vodka instance launcher :) "
  print_green "https://v0dka-developments.github.io/v0dka-Instance-Launcher-Docs/"
  echo " "
  echo " "
  echo " "
  echo " "


}










#### end of functions


#cheat way to find current distro

version=$(gcc --version | grep -o 'Ubuntu\|Debian')
## verify we are Debian or Ubuntu
if [ -n "$version" ] && [ "$version" == "Ubuntu" -o "$version" == "Debian" ]
then
  echo "You are currently using distro: $version"
  ## now we check
  if [ $# -gt 0 ]
  then
    if [ "$1" == "full" ]
    then
      print "I should do full install"

      print "i am checking python is installed"
      verify_python
      print "i am checking pip is installed"
      verify_pip
      print "i am now installing linux packages needed"
      install_linux_packages
      print "i am now installing mysql"
      install_mysql
      print "doing full install api+launcher for vodka instance launcher"
      install_full

      print " everything is now installed woo! lets do a recap of everything.."
      logo
      print "#################################################################"
      print_green " admin control panel: http://$IP:8090/control_me"
      print_green " control panel password: $API_LOGIN_PASSWORD"
      print_green " control panel user is: admin"
      print "#################################################################"
      print_green " mysql user is $MYSQL_NEW_USER"
      print_green " mysql password is $MYSQL_PASSWORD_USER"
      print_green " your root password for mysql is: $MYSQL_PASSWORD"
      print "#################################################################"
      print " thank you for using the vodka instance launcher :) "
      print_green "https://v0dka-developments.github.io/v0dka-Instance-Launcher-Docs/"
      echo " "
      echo " "
      echo " "
      echo " "

      

    fi

    if [ "$1" == "api" ]
    then
      print "i am checking python is installed"
      verify_python
      print "i am checking pip is installed"
      verify_pip
      print "i am now installing linux packages needed"
      install_linux_packages
      print "i am now installing mysql"
      install_mysql
      print "now installing the api"
      install_api
      print " everything is now installed woo! lets do a recap of everything.."
      logo
      print "#################################################################"
      print_green " admin control panel: http://$IP:8090/control_me"
      print_green " control panel password: $API_LOGIN_PASSWORD"
      print_green " control panel user is: admin"
      print "#################################################################"
      print_green " mysql user is $MYSQL_NEW_USER"
      print_green " mysql password is $MYSQL_PASSWORD_USER"
      print_green " your root password for mysql is: $MYSQL_PASSWORD"
      print "#################################################################"
      print_green "Secret Key for the instance launchers: $SERVER_ADD_SECRET_KEY"
      print " thank you for using the vodka instance launcher :) "
      print_green "https://v0dka-developments.github.io/v0dka-Instance-Launcher-Docs/"
      echo " "
      echo " "
      echo " "
      echo " "
    fi

    if [ "$1" == "launcher" ]
    then
      server_ip=$2
      server_port=$3
      server_pass=$4
      verify_python
      print "i am checking pip is installed"
      verify_pip
      print "i am now installing linux packages needed"
      install_linux_packages
      if [[ $server_ip =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
          if ! [[ $server_port =~ ^[0-9]+$ ]] ; then
            print_red "error: Not a valid port number" >&2; exit 1
          else 
            url="http://$server_ip:$server_port/priv_key?password=$server_pass"
            pass=$(curl -s $url)
           # echo "$pass"
            if echo "$pass" | grep -q "Internal Server Error"; then
                print_red "there was an issue getting the key, validate ip, port and password"
            else
                install_launcher $pass $server_ip $server_port
            fi
          fi
      else
          print_red "error: Not a valid ip address" >&2; exit 1
      fi
      
    fi

    
  else
    print_red "No parameters passed usage install.sh full or install.sh api or install.sh launcher"
  fi

else
  print_red "Sorry, I can't install on this OS. Currently I only support Debian and Ubuntu."
fi
