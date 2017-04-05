Sandbox of docker orchestration
==============================
This is sample build docker swarm cluster over TLS using Terraform on DigitalOcean.


Get Started
------------------------------

#### setting
```sh
cp terraform.tfvars.sample terraform.tfvars
vi terraform.tfvars
```

#### plan and apply
```sh
terraform plan
terraform apply
```
it output tls keys to `keys` directory.

#### e.g. docker usage
```sh
docker --tlsverify \
  --tlscacert=keys/ca.pem \
  --tlscert=keys/cert.pem \
  --tlskey=keys/key.pem \
  -H=(ipv4_address of first host):2376 \
  info
```
or
```sh
export DOCKER_TLS_VERIFY="1"
export DOCKER_CERT_PATH="/path/to/keys"
export DOCKER_HOST="tcp://(ipv4_address of first host):3376"

docker info
```


License
------------------------------
[MIT](./LICENSE)
