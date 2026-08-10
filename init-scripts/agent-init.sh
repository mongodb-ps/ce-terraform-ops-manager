#!/bin/bash
PKG_NAME=""
for DISTRO in ubuntu2204 ubuntu2004 ubuntu1604; do
  PKG_NAME="mongodb-mms-automation-agent-manager_${OM_AUTOMATION_VERSION}_amd64.$DISTRO.deb"
  curl -fOL "${OM_URL}download/agent/automation/$PKG_NAME" && break
  PKG_NAME=""
done
if [ -z "$PKG_NAME" ]; then
  echo "Failed to download the automation agent package" >&2
  exit 1
fi
sudo dpkg -i "$PKG_NAME"
sudo sed -i 's/^\(mmsGroupId=\).*/\1'"${OM_GROUP_ID}"'/' /etc/mongodb-mms/automation-agent.config
sudo sed -i 's/^\(mmsApiKey=\).*/\1'"${OM_API_KEY}"'/' /etc/mongodb-mms/automation-agent.config
sudo sed -i 's%^\(mmsBaseUrl=\).*%\1'"${OM_URL}"'%' /etc/mongodb-mms/automation-agent.config
sudo systemctl start mongodb-mms-automation-agent

sudo mkdir -p /data
sudo chown mongodb:mongodb /data
sudo apt-get update && sudo apt-get install -y libcurl4 libgssapi-krb5-2 libldap-2.5-0 libwrap0 libsasl2-2 libsasl2-modules libsasl2-modules-gssapi-mit snmp openssl liblzma5