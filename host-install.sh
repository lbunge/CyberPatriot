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
echo "VNC Password is: $vncPass" >> /tmp/scriptOutput.txt

### Modifies the host vm's

apt update; apt update; apt update
apt install -y xfce4 xfce4-goodies
apt install -y tightvncserver

# Create the password & config file for the vnc service
[[ ! -d /home/$newUser/.vnc ]] && mkdir /home/$newUser/.vnc
echo $vncPass | vncpasswd -f > /home/$newUser/.vnc/passwd
echo "#!/bin/bash" > /home/$newUser/.vnc/xstartup
echo "xrdb $HOME/.Xresources" >> /home/$newUser/.vnc/xstartup
echo "startxfce4 &" >> /home/$newUser/.vnc/xstartup

# Ensure the proper permissions are set
chown -R $newUser:$newUser /home/$newUser/.vnc
chmod 0600 /home/$newUser/.vnc/passwd
chmod +x /home/$newUser/.vnc/xstartup

# Start the VNC server
sudo -u $newUser vncserver