#!/bin/bash -eu

# install docker
echo "Installing docker ..."
sudo wget -qO- https://get.docker.com/ | sh

# setting docker
sudo mv /tmp/ca.pem /etc/docker
sudo mv /tmp/server-cert.pem /etc/docker
sudo mv /tmp/server-key.pem /etc/docker
DOCKER_OPTS="--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/server-cert.pem --tlskey=/etc/docker/server-key.pem -H=0.0.0.0:2376"
sudo sed -i "s;/usr/bin/dockerd;/usr/bin/dockerd ${DOCKER_OPTS};" \
  /lib/systemd/system/docker.service
sudo systemctl daemon-reload
sudo service docker restart
