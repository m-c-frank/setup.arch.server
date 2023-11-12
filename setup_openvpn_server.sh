#!/bin/bash

# Install OpenVPN and Easy-RSA
sudo pacman -Syu --noconfirm
sudo pacman -S openvpn easy-rsa --noconfirm

# Initialize Easy-RSA and build CA
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
cp vars.example vars
sed -i 's/export KEY_COUNTRY=.*/export KEY_COUNTRY="YourCountry"/' vars
sed -i 's/export KEY_PROVINCE=.*/export KEY_PROVINCE="YourProvince"/' vars
sed -i 's/export KEY_CITY=.*/export KEY_CITY="YourCity"/' vars
sed -i 's/export KEY_ORG=.*/export KEY_ORG="YourOrganization"/' vars
sed -i 's/export KEY_EMAIL=.*/export KEY_EMAIL="YourEmail"/' vars
sed -i 's/export KEY_OU=.*/export KEY_OU="YourOrganizationalUnit"/' vars
source vars
./clean-all
./build-ca --batch

# Build the server certificate, key, and encryption files
./build-key-server --batch server
./build-dh
openvpn --genkey --secret keys/ta.key

# Copy the necessary files to OpenVPN directory
sudo cp ~/openvpn-ca/keys/{server.crt,server.key,ca.crt,dh2048.pem,ta.key} /etc/openvpn/server

# Configure OpenVPN
sudo cp /usr/share/openvpn/examples/server.conf /etc/openvpn/server/server.conf
sudo sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server/server.conf
sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/;group nobody/group nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/ca ca.crt/ca ca.crt\nkey server.key\ncert server.crt\ndh dh2048.pem\ntls-auth ta.key 0/' /etc/openvpn/server/server.conf

# Enable IP Forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start and Enable OpenVPN
sudo systemctl start openvpn-server@server
sudo systemctl enable openvpn-server@server

echo "OpenVPN server setup is complete."

