#!/bin/bash
# Variables
url1=$1
url2=$2
url3=$3
newUser=$4
userPass=$5
vncPass=${userPass:0:8}

# Updates repos and installs dependencies & tightvncserver
apt update; apt update; apt update  # Need to update repos multiple times
apt install -y xfce4 slim wget gcc build-essential linux-headers-generic linux-headers-$(uname -r) firefox
apt install -y tightvncserver
wget --user-agent="Mozilla/5.0 (X11; Linux x86_64; rv:75.0) Gecko/20100101 Firefox/75.0" https://download3.vmware.com/software/player/file/VMware-Player-15.5.7-17171714.x86_64.bundle

# Install Vmware Workstation Player
chmod +x VMware-Player-15.5.7-17171714.x86_64.bundle
./VMware-Player-15.5.7-17171714.x86_64.bundle

# Get the Images from URLs
wget $url1 -P /home/$newUser/Desktop/
wget $url2 -P /home/$newUser/Desktop/
wget $url3 -P /home/$newUser/Desktop/

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

# Start the display manager and then the VNC server
service slim start
sudo -u $newUser vncserver