#!/bin/bash
curl -OL "${OM_URL}download/agent/automation/mongodb-mms-automation-agent-manager_${OM_AUTOMATION_VERSION}_amd64.ubuntu1604.deb"
sudo dpkg -i "mongodb-mms-automation-agent-manager_${OM_AUTOMATION_VERSION}_amd64.ubuntu1604.deb"
sudo sed -i 's/^\(mmsGroupId=\).*/\1'"${OM_GROUP_ID}"'/' /etc/mongodb-mms/automation-agent.config
sudo sed -i 's/^\(mmsApiKey=\).*/\1'"${OM_API_KEY}"'/' /etc/mongodb-mms/automation-agent.config
sudo sed -i 's%^\(mmsBaseUrl=\).*%\1'"${OM_URL}"'%' /etc/mongodb-mms/automation-agent.config
sudo systemctl start mongodb-mms-automation-agent

sudo mkdir -p /data
sudo chown mongodb:mongodb /data