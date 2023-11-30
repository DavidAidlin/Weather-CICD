Created an SSH key using
```
ssh-keygen -t rsa -b 2048 -f my-aws-key
```
Applied the terraform configuration files to create a VPC, IGW, Subnet, Route tables..
Also created the relevant EC2 Instances for project [Gitlab, Jenkins Master, Jenkins Agent, Deployment]

SSHed into the Gitlab Instance and applied the following script:
```
sudo apt update
sudo apt install apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
apt-cache policy docker-ce
sudo apt install docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
su - ${USER}
docker --version

```

To install Docker and add the relevant user as a user
