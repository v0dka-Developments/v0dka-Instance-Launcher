#!/bin/bash


sudo apt update && sudo apt upgrade -y
## we require these for packages to install them before we continue
sudo apt-get install gcc openssl -y



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



### functions



## colours
function print_green {
    echo -e "\033[32m$1\033[0m"
}

# function to print text in red color
function print_red {
    echo -e "\033[31m$1\033[0m"
}

function print {
    echo -e "\033[38;5;208m$1\033[0m"
}

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


  cd ~/ && wget https://repo.mysql.com//mysql-apt-config_0.8.24-1_all.deb 
  
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
  sudo systemctl status mysql

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
  sed -i "s/username/$USER/g" ./ServerInstanceManagerWebApi/vodka_api.service


  ### ok now we have configured everything lets pip install the requirements
  pip install -r ./ServerInstanceManagerWebApi/requirements.txt 

  ## now lets copy the service file to systemd
  sudo cp ./ServerInstanceManagerWebApi/vodka_api.service /etc/systemd/system/vodka_api.service

  ### the api setup should now be complete lets do the launcher
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServiceInstanceManager/config.py
  sed -i "s/Domain = \".*\"/Domain = \"$IP\"/" ./ServiceInstanceManager/config.py
  sed -i 's/\bPort = .*$/Port = 8090/' ./ServiceInstanceManager/config.py
  ## update the service file...
  sed -i "s/username/$USER/g" ./ServiceInstanceManager/vodka_manager.service
  ## copy service to systemd
  sudo cp ./ServiceInstanceManager/vodka_manager.service /etc/systemd/system/vodka_manager.service
  ## install pip requirements
  pip install -r ./ServiceInstanceManager/requirements.txt 


  ## reload systemd
  sudo systemctl daemon-reload
  ## start the services
  sudo systemctl enable vodka_api.service
  sudo systemctl enable vodka_manager.service
  sudo service vodka_api start 
  sudo service vodka_manager start 


}


install_api(){

  print "_____________________________________"
  print "|  now installing the API            |"
  print "______________________________________"
  
  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  rm -rf ./database # we dont need this directory as we already installed db from raw github output
  rm -rf ./ServiceInstanceManager # we dont need launcher so lets remove launcher
  
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
  sed -i "s/username/$USER/g" ./ServerInstanceManagerWebApi/vodka_api.service


  ### ok now we have configured everything lets pip install the requirements
  pip install -r ./ServerInstanceManagerWebApi/requirements.txt 

  ## now lets copy the service file to systemd
  sudo cp ./ServerInstanceManagerWebApi/vodka_api.service /etc/systemd/system/vodka_api.service
  sudo systemctl daemon-reload
  sudo systemctl enable vodka_api.service
  sudo service vodka_api start 
}


install_launcher(){

  print "_____________________________________"
  print "|  now installing the Launcher       |"
  print "______________________________________"
  key=$1
  sever_ip=$2
  server_port=$3


  echo "i am the key $key"
  echo "i am the serverip $server_ip"
  echo "i am the server port $server_port"
  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  rm -rf ./database # we dont need this directory as we already installed db from raw github output
  rm -rf ./ServerInstanceManagerWebApi # we only need the instance launcher not the api so lets remove



  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServiceInstanceManager/config.py
  sed -i "s/Domain = \".*\"/Domain = \"$IP\"/" ./ServiceInstanceManager/config.py
  sed -i 's/\bPort = .*$/Port = 8090/' ./ServiceInstanceManager/config.py
  ## update the service file...
  sed -i "s/username/$USER/g" ./ServiceInstanceManager/vodka_manager.service
  ## copy service to systemd
  sudo cp ./ServiceInstanceManager/vodka_manager.service /etc/systemd/system/vodka_manager.service
  ## install pip requirements
  pip install -r ./ServiceInstanceManager/requirements.txt 

  

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
      print_green " admin control panel: http://$IP:8090/controlme"
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
      print_green " admin control panel: http://$IP:8090/controlme"
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

    if [ "$1" == "launcher" ]
    then
      server_ip=$2
      server_port=$3
      server_pass=$4
      echo $server_ip 
      echo $server_port
      echo $server_pass
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
