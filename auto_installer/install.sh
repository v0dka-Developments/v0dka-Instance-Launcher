#!/bin/bash

### logo :D

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


### not for self use masterpassword auth for getting server add secret key



### global vars 
MYSQL_PASSWORD=$(openssl rand -hex 20)
MYSQL_PASSWORD_USER=$(openssl rand -hex 20)
MYSQL_NEW_USER="vodka_instance"
APP_SECRET_KEY = $(openssl rand -hex 40)
API_LOGIN_PASSWORD = $(openssl rand -hex 15)
SERVER_ADD_SECRET_KEY = $(openssl rand -hex 30)
IP=$(curl -s ifconfig.me)



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
  sudo apt update && sudo apt upgrade


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
        print_red "Python 3 is not installed"
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
    sudo apt-get install python3-pip
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
  sudo apt install ./mysql-apt-config_*_all.deb
  update_upgrade 
  ## generate random secure password
  

  ## generate file for unattened install with secure password
  cat > ~/mysql_config.cnf << EOF
[mysql]
mysql-server mysql-server/root_password password $MYSQL_PASSWORD
mysql-server mysql-server/root_password_again password $MYSQL_PASSWORD
  EOF

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server --defaults-file=~/mysql_config.cnf


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

  sudo mysql_secure_installation <<EOF
$MYSQL_PASSWORD
y
n
y
y
EOF

print " Secure install now complete, i now creating new user and password"

mysql -u root -p"$MYSQL_PASSWORD" <<EOF
CREATE USER '$MYSQL_NEW_USER'@'localhost' IDENTIFIED BY '$MYSQL_PASSWORD_USER';
CREATE USER '$MYSQL_NEW_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD_USER';
GRANT ALL ON *.* TO '$MYSQL_NEW_USER'@'localhost';
GRANT ALL ON *.* TO '$MYSQL_NEW_USER'@'%';
FLUSH PRIVILEGES;
EOF


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

  mysql -u vodka_instance -p $MYSQL_PASSWORD_USER < ~/current.sql

  print "database has now been created"

}


install_full(){

  print"_____________________________________"
  print"|  now installing the full launcher! |"
  print"______________________________________"


  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher
  cd ./v0dka-Instance-Launcher
  rm -rf ./database # we dont need this directory as we already installed db from raw github output
  
  ## lets update the api configs first
  sed -i "s/Master_Password = \".*\"/Master_Password = \"$API_LOGIN_PASSWORD\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/AppSecretKey = \".*\"/AppSecretKey = \"$APP_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/IP = \".*\"/IP = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Debug = ".*"/Debug = False/' ./ServerInstanceManagerWebApi/config.py

  
  sed -i "s/Host = \".*\"/Host = \"$IP\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i 's/Database = ".*"/Database = vodkainstancemanager/' ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Username = \".*\"/Username = \"$MYSQL_NEW_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/Password = \".*\"/Password = \"$MYSQL_PASSWORD_USER\"/" ./ServerInstanceManagerWebApi/config.py
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServerInstanceManagerWebApi/config.py


  # now lets configure the service file cheat way lets just regex for username and replace for current logged in user...
  sed -i 's/username/$USER/g' ./ServerInstanceManagerWebApi/vodka_api.service


  ### ok now we have configured everything lets pip install the requirements
  pip install -r ./ServerInstanceManagerWebApi/requirements.txt 

  ## now lets copy the service file to systemd
  sudo cp ./ServerInstanceManagerWebApi/vodka_api.service /etc/systemd/system/vodka_api.service

  ### the api setup should now be complete lets do the launcher
  sed -i "s/ServerAddSecretKey = \".*\"/ServerAddSecretKey = \"$SERVER_ADD_SECRET_KEY\"/" ./ServiceInstanceManager/config.py
  ## update the service file...
  sed -i 's/username/$USER/g' ./ServiceInstanceManager/vodka_manager.service
  ## copy service to systemd
  sudo cp ./ServiceInstanceManager/vodka_manager.service /etc/systemd/system/vodka_manager.service
  ## install pip requirements
  pip install -r ./ServiceInstanceManager/requirements.txt 


  ## reload systemd
  sudo systemctl daemon-reload
  ## start the services
  sudo service vodka_api start 
  sudo service vodka_manager start


}


install_api(){

  git clone https://github.com/v0dka-Developments/v0dka-Instance-Launcher

}

install_launcher(){

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

      print "#################################################################"
      print_green " admin control panel: http://$IP:8090/controlme"
      print_green " control panel password: $API_LOGIN_PASSWORD"
      print_green " control panel user is: admin"
      print "#################################################################"
      print_green " mysql user is $MYSQL_NEW_USER"
      print_green " mysql password is $MYSQL_PASSWORD_USER"
      print_red " your root password for mysql is: $MYSQL_PASSWORD"
      print "#################################################################"
      print " thank you for using the vodka instance launcher :) "

      

    fi

    if [ "$1" == "api" ]
    then
      print "I should only install API"
    fi

    if [ "$1" == "launcher" ]
    then
      print "I should install the launcher"
    fi

    
  else
    print "No parameters passed usage install.sh full or install.sh api or install.sh launcher"
  fi

else
  print "Sorry, I can't install on this OS. Currently I only support Debian and Ubuntu."
fi
