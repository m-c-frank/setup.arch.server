#!/bin/bash

# Variables
SERVER_HOSTNAME="goldenportal"
REMOTE_CERT_PATH="~/openvpn-ca/keys"
LOCAL_CERT_PATH="~/openvpn_client_keys"

# Install OpenVPN
sudo pacman -Syu --noconfirm
sudo pacman -S openvpn --noconfirm

# Create a directory to store keys
mkdir -p $LOCAL_CERT_PATH

# Copy the necessary files from the server
scp "$SERVER_HOSTNAME:$REMOTE_CERT_PATH/ca.crt" $LOCAL_CERT_PATH
scp "$SERVER_HOSTNAME:$REMOTE_CERT_PATH/client1.crt" $LOCAL_CERT_PATH
scp "$SERVER_HOSTNAME:$REMOTE_CERT_PATH/client1.key" $LOCAL_CERT_PATH
scp "$SERVER_HOSTNAME:$REMOTE_CERT_PATH/ta.key" $LOCAL_CERT_PATH

# Check if the necessary files are copied
if [ ! -f "$LOCAL_CERT_PATH/ca.crt" ] || [ ! -f "$LOCAL_CERT_PATH/client1.crt" ] || [ ! -f "$LOCAL_CERT_PATH/client1.key" ] || [ ! -f "$LOCAL_CERT_PATH/ta.key" ]; then
    echo "Required files not found in the directory $LOCAL_CERT_PATH. Please check the SCP commands or server path."
    exit 1
fi

# Setup client configuration
cp /etc/openvpn/client/client.conf ~/client.ovpn
sed -i "s|ca ca.crt|ca $LOCAL_CERT_PATH/ca.crt|" ~/client.ovpn
sed -i "s|cert client.crt|cert $LOCAL_CERT_PATH/client1.crt|" ~/client.ovpn
sed -i "s|key client.key|key $LOCAL_CERT_PATH/client1.key|" ~/client.ovpn
sed -i "s|tls-auth ta.key 1|tls-auth $LOCAL_CERT_PATH/ta.key 1|" ~/client.ovpn

echo "OpenVPN client setup is complete. Connect using 'sudo openvpn --config ~/client.ovpn'"

