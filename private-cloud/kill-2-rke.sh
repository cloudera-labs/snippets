#!/bin/bash

# Copyright 2022 Cloudera, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.


echo "Make sure you kill registry and shut down the ECS Services"

input="target-hosts.txt"

#
# modify these values as appropriate for your local environment
#
priv_key="$HOME/systest"
sudo_user="systest"
docker_store='/data/1/docker/*'
longhorn_store='/data/2/ecs/*'
local_store='/data/3/ecs/*'


# work through the host list and ensure that RKE is dead 
# before uninstalling and cleaning up it's OS-level remnant 
#
while read -r -u10 host;
do echo '"'Trying..${host}'"';
ssh -i ${priv_key} -o StrictHostKeyChecking=no ${sudo_user}@${host} "cd /opt/cloudera/parcels/ECS/bin; 
sudo ./rke2-killall.sh;
sudo ./rke2-killall.sh;
sudo ./rke2-uninstall.sh;
sudo [ -d "/var/lib/rancher" ] && echo "Directory /var/lib/rancher exists. rke2-uninstall.sh has failed!";
sudo [ -d "/var/lib/kubelet" ] && echo "Directory /var/lib/kubelet exists. rke2-uninstall.sh has failed!";
sudo rm -rf /var/lib/docker_server/*;
sudo rm -rf /etc/docker/certs.d/*;
echo "Deleting docker, local and longhorn storage";
sudo rm -rf ${docker_store};
sudo rm -rf ${local_store};
sudo rm -rf ${longhorn_store};
sudo systemctl stop iscsid;
#sudo yum -y erase iscsi-initiator-utils;
sudo rm -rf /var/lib/iscsi;
sudo rm -rf /etc/cni;
sudo rm -f /run/longhorn-iscsi.lock;
sudo rm -rf /run/k3s;
sudo rm -rf /run/containerd;
sudo rm -rf /var/lib/docker;
sudo rm -rf /var/log/containers;
sudo rm -rf /var/log/pods;
echo "Reset iptables to ACCEPT all, then flush and delete all other chains";
declare -A chains=(
[filter]=INPUT:FORWARD:OUTPUT
[raw]=PREROUTING:OUTPUT
[mangle]=PREROUTING:INPUT:FORWARD:OUTPUT:POSTROUTING
[security]=INPUT:FORWARD:OUTPUT
[nat]=PREROUTING:INPUT:OUTPUT:POSTROUTING
)
for table in "${!chains[@]}"; do
echo "${chains[$table]}" | tr : $"\n" | while IFS= read -r; do
sudo iptables -t "$table" -P "$REPLY" ACCEPT
done
sudo iptables -t "$table" -F
sudo iptables -t "$table" -X
done
sudo /usr/sbin/ifconfig docker0 down;
sudo /usr/sbin/ip link delete docker0;
sudo /usr/sbin/reboot now
";
done 10< "$input"

echo "Now you can Delete the ECS Cluster in CM"
