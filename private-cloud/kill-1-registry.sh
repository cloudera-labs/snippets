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


input="target-hosts.txt"

#
# modify these values as appropriate for your local environment
#
priv_key="$HOME/systest"
sudo_user="systest"

# stop the registry container and remove it
while read -r -u10 host;
do echo '"'Trying..${host}'"';
ssh -i ${priv_key} -o StrictHostKeyChecking=no ${sudo_user}@${host} "
sudo /opt/cloudera/parcels/ECS/docker/docker container stop registry;
sudo /opt/cloudera/parcels/ECS/docker/docker container rm -v registry;
sudo /opt/cloudera/parcels/ECS/docker/docker image rm registry:2";
done 10< "$input"

echo "Registry killed, now shut down ECS service"
