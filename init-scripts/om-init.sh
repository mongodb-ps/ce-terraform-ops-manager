#!/bin/bash
# Download and install MongoDB Ops Manager
curl -OL ${OM_DOWNLOAD_URL}
sudo dpkg -i *.deb

# Customize Ops Manager configuration
echo -e "
mms.centralUrl=http://$(curl 169.254.169.254/latest/meta-data/public-hostname):8080
mms.fromEmailAddr=admin@dummy.com
mms.replyToEmailAddr=admin@dummy.com
mms.adminEmailAddr=admin@dummy.com
mms.emailDaoClass=com.xgen.svc.core.dao.email.JavaEmailDao
mms.mail.transport=smtp
mms.mail.hostname=smtp.dummy.com
mms.mail.port=25
mms.ignoreInitialUiSetup=true
" | sudo tee -a /opt/mongodb/mms/conf/conf-mms.properties

raw_pwd=${OM_APPDB_PASSWORD}
escaped=$(python3 -c "import urllib.parse; print(urllib.parse.quote('$raw_pwd'))")
sudo sed -i "s#^mongo\.mongoUri=.*#mongo.mongoUri=mongodb://${OM_APPDB_USER}:$escaped@${OM_APPDB_HOSTS}/admin#" /opt/mongodb/mms/conf/conf-mms.properties

# Set the systemd service to auto-restart on failure.
# Because sometimes MongoDB Ops Manager service may start before MongoDB is ready.
service="mongodb-mms.service"
sudo mkdir -p /etc/systemd/system/$service.d
cat <<'EOF' | sudo tee /etc/systemd/system/$service.d/override.conf > /dev/null
[Service]
Restart=on-failure
RestartSec=5
StartLimitIntervalSec=0
EOF

sudo systemctl daemon-reload
sudo systemctl enable mongodb-mms
sudo systemctl start mongodb-mms
sudo mkdir -p /data/head
sudo chown -R mongodb-mms:mongodb-mms /data/head