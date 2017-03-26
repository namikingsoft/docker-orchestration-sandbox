#!/bin/bash -e

# install docker
echo "Installing docker ..."
wget -qO- https://get.docker.com/ | sh

# setting docker
mv /tmp/ca.pem /etc/docker
mv /tmp/server-cert.pem /etc/docker
mv /tmp/server-key.pem /etc/docker
DOCKER_OPTS="--tlsverify --tlscacert=/etc/docker/ca.pem --tlscert=/etc/docker/server-cert.pem --tlskey=/etc/docker/server-key.pem -H=0.0.0.0:2376"
sed -i "s;/usr/bin/dockerd;/usr/bin/dockerd ${DOCKER_OPTS};" \
  /lib/systemd/system/docker.service
systemctl daemon-reload
service docker restart
