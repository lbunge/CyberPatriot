url1 = $1
url2 = $2
url3 = $3
newUser = $4
userPass = $5

echo "Url 1 is: $url1" >> /tmp/scriptOutput.txt
echo "Url 1 is: $url2" >> /tmp/scriptOutput.txt
echo "Url 1 is: $url3" >> /tmp/scriptOutput.txt
echo "Username is: $newUser" >> /tmp/scriptOutput.txt
echo "User Password is: $userPass" >> /tmp/scriptOutput.txt

### Modifies the host vm's

# apt update; apt -y upgrade
# apt-get install -y xfce4 xfce4-goodies
# apt-get install -y tightvncserver