#!/bin/bash

url1=$1
url2=$2
url3=$3
newUser=$4
userPass=$5
vncPass=${userPass:0:8}
echo "Url 1 is: $url1" >> /tmp/scriptOutput.txt
echo "Url 1 is: $url2" >> /tmp/scriptOutput.txt
echo "Url 1 is: $url3" >> /tmp/scriptOutput.txt
echo "Username is: $newUser" >> /tmp/scriptOutput.txt
echo "User Password is: $userPass" >> /tmp/scriptOutput.txt

### Modifies the host vm's

apt update; apt -y upgrade
apt-get install -y xfce4 xfce4-goodies
apt-get install -y tightvncserver

# Create the password for the vnc service
mkdir /home/$newUser/.vnc
echo $vncPass | vncpasswd -f > /home/$newUser/.vnc/passwd
chown -R $newUser:$newUser /home/$newUser/.vnc
chmod 0600 /home/$newUser/.vnc/passwd