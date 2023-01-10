#!/bin/bash

echo ""
scripts_dir="$(dirname "${BASH_SOURCE[0]}")"
RUN_AS="$(ls -ld "$scripts_dir" | awk 'NR==1 {print $3}')"
if [ "$USER" != "$RUN_AS" ]
then
    echo "This script must run as $RUN_AS, trying to change user..."
    exec sudo -u $RUN_AS $0
fi
echo ""
echo ""
echo "Awesome... Lets get started..."
echo ""
echo ""
sudo apt-get update

if [[ $(uname -m|grep "armv7") ]] || [[ $(uname -m|grep "armv8") ]] || [[ $(uname -m|grep "aarch64") ]]; then
  echo ""
  echo ""
  echo "Supports Java JDK 11"
  devmodel="armv7"
  echo ""
  echo ""
else
  echo ""
  echo ""
  echo "Requires Java JDK 8"
  devmodel="armv6"
  echo ""
  echo ""
fi

if [[ $devmodel = "armv6" ]];then
  wget https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/openjdk-8-jdk_8u312-b07-1_armhf.deb
  wget https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/openjdk-8-jre_8u312-b07-1_armhf.deb
  sudo apt-get install ./openjdk-8-jdk_8u312-b07-1.deb9u1_armhf.deb -f
  sudo apt-get install ./openjdk-8-jdk_8u312-b07-1_armhf.deb
  sudo apt-get install ./openjdk-8-jre_8u312-b07-1_armhf.deb
  sudo apt-get install openssl -y
else
  sudo apt-get install openjdk-11-jdk openjdk-11-jre openssl -f -y
fi

sudo apt-get install openssl
mkdir -p /home/${USER}/Blynk/data
cd /home/${USER}/Blynk

wget https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/server.properties
wget https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/mail.properties

if [[ $devmodel = "armv6" ]];then
  wget -c https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/server-0.41.16-java8.jar -O server.jar
  echo ""
  echo ""
  echo "Creating self-signed certificates..................."
  echo ""
  echo ""
  openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout server.key -out server.crt
  openssl pkcs8 -topk8 -inform PEM -outform PEM -in server.key -out server.pem
  read -r -p "Enter the Certificates password once again to be added to the server.properties file: " sslpass
  echo ""
  echo ""
  sed -i 's|server.ssl.cert=|server.ssl.cert=/home/'${USER}'/Blynk/server.crt|g' /home/${USER}/Blynk/server.properties
  sed -i 's|server.ssl.key=|server.ssl.key=/home/'${USER}'/Blynk/server.pem|g' /home/${USER}/Blynk/server.properties
  sed -i 's|server.ssl.key.pass=|server.ssl.key.pass='$sslpass'|g' /home/${USER}/Blynk/server.properties
else
  wget -c https://github.com/shivasiddharth/blynk-server/releases/download/v0.41.16/server-0.41.16.jar -O server.jar
  echo ""
  echo ""
  echo "Creating self-signed certificates..................."
  echo ""
  echo ""
  openssl req -x509 -nodes -days 1825 -newkey rsa:2048 -keyout server.key -out server.crt
  openssl pkcs8 -topk8 -v1 PBE-SHA1-2DES -in server.key -out server.enc.key
  read -r -p "Enter the Certificates password once again to be added to the server.properties file: " sslpass
  echo ""
  echo ""
  sed -i 's|server.ssl.cert=|server.ssl.cert=/home/'${USER}'/Blynk/server.crt|g' /home/${USER}/Blynk/server.properties
  sed -i 's|server.ssl.key=|server.ssl.key=/home/'${USER}'/Blynk/server.enc.key|g' /home/${USER}/Blynk/server.properties
  sed -i 's|server.ssl.key.pass=|server.ssl.key.pass='$sslpass'|g' /home/${USER}/Blynk/server.properties
fi


read -p "Do you wish to set the server to autostart on boot?" yn
case $yn in
    [Yy]*)
            echo ""
            echo ""
            echo "Setting local to auto start on boot...."
            sudo sed -i '1s/^/# /' /etc/rc.local
            sudo sed -i '/exit/d' /etc/rc.local
            sudo sh -c "echo 'sudo java -jar /home/${USER}/Blynk/server.jar -dataFolder /home/${USER}/Blynk/data -serverConfig /home/${USER}/Blynk/server.properties -mailConfig /home/${USER}/Blynk/mail.properties &' >> /etc/rc.local"
            sudo sh -c "echo 'exit 0' >> /etc/rc.local"
            sudo systemctl enable rc-local
            echo "All done... Make sure to add the certificate password in the server.properties file..."
            echo ""

            ;;
    [Nn]* )
            echo ""
            echo ""
            echo "You can manually start the assistant using:"
            echo ""
            echo "sudo java -jar /home/${USER}/Blynk/server.jar -dataFolder /home/${USER}/Blynk/data -serverConfig /home/${USER}/Blynk/server.properties -mailConfig /home/${USER}/Blynk/mail.properties &"
            echo ""
            echo ""
            echo "All done... Make sure to add the certificate password in the server.properties file..."
            echo ""
            exit;;
    * ) echo "Please answer yes or no.";;
esac
