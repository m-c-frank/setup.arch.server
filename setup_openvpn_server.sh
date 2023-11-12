#!/bin/bash

# Install OpenVPN and Easy-RSA
sudo pacman -Syu --noconfirm
sudo pacman -S openvpn easy-rsa --noconfirm

# Easy-RSA Configuration
EASY_RSA="/etc/easy-rsa/"
PKI_DIR="$EASY_RSA/pki"
sudo mkdir -p "$EASY_RSA"
sudo cp -r /usr/share/easy-rsa/* "$EASY_RSA" || { echo "Easy-RSA files not found. Exiting."; exit 1; }
cd "$EASY_RSA" || { echo "Failed to change directory to $EASY_RSA. Exiting."; exit 1; }

# Initialize and build the CA
sudo ./easyrsa init-pki
sudo ./easyrsa build-ca nopass || { echo "Failed to build CA. Exiting."; exit 1; }

# Generate Server Certificate, Key, and Encryption Files
sudo ./easyrsa gen-req server nopass
sudo ./easyrsa sign-req server server
sudo ./easyrsa gen-dh || { echo "Failed to generate DH parameters. Exiting."; exit 1; }

# Generate ta.key for TLS Authentication
sudo openvpn --genkey secret ta.key || { echo "Failed to generate ta.key. Exiting."; exit 1; }

# Copy the necessary files to OpenVPN directory
sudo cp "$PKI_DIR/ca.crt" "$PKI_DIR/issued/server.crt" "$PKI_DIR/private/server.key" "$PKI_DIR/dh.pem" ta.key /etc/openvpn/server || { echo "Failed to copy certificate files. Exiting."; exit 1; }

# Configure OpenVPN
sudo cp /usr/share/openvpn/examples/server.conf /etc/openvpn/server/server.conf || { echo "Failed to copy server.conf. Exiting."; exit 1; }
sudo sed -i 's/;tls-auth ta.key 0/tls-auth ta.key 0/' /etc/openvpn/server/server.conf
sudo sed -i 's/;user nobody/user nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/;group nobody/group nobody/' /etc/openvpn/server/server.conf
sudo sed -i 's/ca ca.crt/ca ca.crt\nkey server.key\ncert server.crt\ndh dh.pem\ntls-auth ta.key 0/' /etc/openvpn/server/server.conf

# Update the OpenVPN Server Configuration
sudo sed -i 's/;topology subnet/topology subnet/' /etc/openvpn/server/server.conf
sudo sed -i 's/;cipher AES-256-CBC/cipher AES-256-GCM/' /etc/openvpn/server/server.conf
sudo sed -i 's/;data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305/data-ciphers AES-256-GCM:AES-128-GCM:CHACHA20-POLY1305/' /etc/openvpn/server/server.conf

# Enable IP Forwarding
echo 'net.ipv4.ip_forward = 1' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Start and Enable OpenVPN
sudo systemctl start openvpn-server@server || { echo "Failed to start OpenVPN server. See systemctl status for details. Exiting."; exit 1; }
sudo systemctl enable openvpn-server@server

echo "OpenVPN server setup is complete."

