#!/bin/bash

# Install and init MongoDB
sudo apt-get install -y gnupg curl
if [ "${OM_APPDB_VERSION}" == "8.0" ]; then
  echo "Installing MongoDB 8.0"
  curl -fsSL https://pgp.mongodb.com/server-8.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg \
    --dearmor
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] https://repo.mongodb.com/apt/ubuntu jammy/mongodb-enterprise/8.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-enterprise-8.0.list
elif [ "${OM_APPDB_VERSION}" == "7.0" ]; then
  echo "Installing MongoDB 7.0"
  curl -fsSL https://pgp.mongodb.com/server-7.0.asc | \
    sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg \
    --dearmor
  echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.com/apt/ubuntu jammy/mongodb-enterprise/7.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-enterprise-7.0.list
fi
sudo apt-get update
sudo apt-get install mongodb-enterprise -y
# Configure MongoDB
echo 'storage:
  dbPath: /var/lib/mongodb
systemLog:
  destination: file
  logAppend: true
  path: /var/log/mongodb/mongod.log
net:
  port: 27017
  bindIp: 0.0.0.0
processManagement:
  timeZoneInfo: /usr/share/zoneinfo
security:
  authorization: enabled' | sudo tee /etc/mongod.conf
sudo systemctl start mongod
sleep 5
# Create admin user
mongosh --eval 'db.getSiblingDB("admin").createUser({user:"${OM_APPDB_USER}", pwd:"${OM_APPDB_PASSWORD}", roles:[{role:"root", db:"admin"}]})'
mongosh --eval 'db.getSiblingDB("cloudconf").getCollection("config.globalWhitelists").insertOne({cidrBlock: "${WHITELIST_CIDR}",type: "GLOBAL_ROLE",description: "current",created: new Date(),updated: new Date()})' -u '${OM_APPDB_USER}' -p '${OM_APPDB_PASSWORD}' --host localhost --authenticationDatabase admin
sudo systemctl enable mongod

sudo apt-get install -y libcurl4 libgssapi-krb5-2 libldap-2.5-0 libwrap0 libsasl2-2 libsasl2-modules libsasl2-modules-gssapi-mit snmp openssl liblzma5