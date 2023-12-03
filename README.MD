I developed a Python weather web application using Flask, Jinja2, and Python. This application features an API call to a complimentary weather service, from which I retrieve essential data, reformat it into JSON, and then present the results. The app employs Jinja2 templates and a Gunicorn WSGI web server, designed to handle multiple user requests simultaneously by creating a separate worker for each request. Additionally, I have configured a Nginx server in front of the WSGI server to facilitate SSL termination and static content caching. The specific configuration details for the Nginx server are as follows:

```
user www-data;
worker_processes auto;
pid /run/nginx.pid;
# include /etc/nginx/modules-enabled/*.conf;

events {
        worker_connections 768;
}

http {
	log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                          '$status $body_bytes_sent "$http_referer" '
                          '"$http_user_agent" "$http_x_forwarded_for"';
	access_log /var/log/nginx/access.log;
	error_log /var/log/nginx/error.log;
	
        sendfile on;
        tcp_nopush on;
        types_hash_max_size 2048;
                
        #include /etc/nginx/mime.types;
        default_type application/octet-stream;


        limit_conn_zone $binary_remote_addr zone=conn_limit_per_ip:1111500;
        server_names_hash_bucket_size 64;
        
        server {
    		listen 8080;
    		listen [::]:8080;
    		
    		location / {
   			return 301 https://$host$request_uri;
   		}
	}

	server {
   		 listen 443 ssl;
    		 listen [::]:443 ssl;
    		 ssl_certificate /etc/nginx/cert.pem;
    		 ssl_certificate_key /etc/nginx/key.pem;

    		 location / {
        		#include proxy_params;
        		proxy_set_header Host $http_host;
       		        proxy_set_header X-Real-IP $remote_addr;
      		        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    		        proxy_set_header X-Forwarded-Proto $scheme;
        		proxy_pass http://app:5000;
   		 }
	}

}
```
the rest of the nginx files are encrypted so I didn't upload them.  
Here is the dockerfile for the final web app and installation and binding for the gunicron WSGI in the dockerfile :
```
FROM python:3.9-slim
WORKDIR /app
COPY . .
RUN pip install -r requirements.txt
CMD gunicorn --bind 0.0.0.0:5000 wsgi:app
```
And here is the Nginx Dockerfile:
```
FROM nginx:latest
COPY nginx.conf /etc/nginx/nginx.conf
COPY cert.pem /etc/nginx/cert.pem
COPY key.pem /etc/nginx/key.pem
```

Then I moved to create my infrastructure on AWS so I Created a local SSH key using
```
ssh-keygen -t rsa -b 2048 -f my-aws-key
```
Applied the terraform configuration files to create VPC, IGW, Subnet, and Route tables...
Also created the relevant EC2 Instances for the project [Gitlab, Jenkins Master, Jenkins Agent, Deployment]

SSHed into the Gitlab Instance and applied the following script:
To install Docker and add the relevant user as a user with the right permissions  
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

Then on the GitLab instance I just created I installed the following script :  
Created a script to retrieve the public IP of the instance and assign it to the GitLab configuration file.
```
import requests
import subprocess

# Get the public IP of the EC2 instance
response = requests.get('http://169.254.169.254/latest/meta-data/public-ipv4')
public_ip = response.text

# Command to modify the GitLab configuration file inside the container
modify_config_cmd = [
    'docker', 
    'exec', 
    'ubuntu_web_1', 
    'sed', 
    '-i', 
    f's|^external_url.*$|external_url "http://{public_ip}/"|', 
    '/etc/gitlab/gitlab.rb'
]

# Modify the GitLab configuration file inside the container
subprocess.run(modify_config_cmd)

# Restart the GitLab container for changes to take effect
subprocess.run(['docker', 'restart', 'ubuntu_web_1'])

print('GitLab configuration updated successfully.')
```
And I Created a systemd service called gitlab-config.service to run the script on boot.
```
[Unit]
Description=Update GitLab Configuration
After=network.target

[Service]
ExecStart=/usr/bin/python3 /home/ubuntu/external_ip.py
WorkingDirectory=/home/ubuntu
Restart=no

[Install]
WantedBy=multi-user.target
```

**Then I Created a Non-Root User and Repository:**

   - Signed in to the root account on the EC2 GitLab instance.
   - Created a non-root user.
   - Approved the user and created a GitLab repository.
   - Generated a Personal Access Token (PAT).
   - Cloned the repository to my laptop using the following command:

     ```bash
     git clone http://44.201.4.72/ban898/project.git
     ```

   - Saved the cloned repository to a folder on my laptop.

**Then SSHed Created to the Jenkins Master Instance:**
   - Installed Jenkins using the following commands :  
   ```
   sudo apt update
   sudo apt install fontconfig openjdk-17-jre
   java -version
   openjdk version "17.0.8" 2023-07-18
   OpenJDK Runtime Environment (build 17.0.8+7-Debian-1deb12u1)
   OpenJDK 64-Bit Server VM (build 17.0.8+7-Debian-1deb12u1, mixed mode, sharing)
   ```
   ```
   sudo systemctl enable jenkins  
   sudo systemctl start jenkins
   ```
   - Browsed to http://localhost:8080 to unlock Jenkins
   - then to retrieve the initial password I used the following command :
   ```
   sudo cat /var/lib/jenkins/secrets/initialAdminPassword
   ```
   - Signed in to the root account on the EC2 Jenkins instance.
   - Created a 
   - Generated a Personal Access Token (PAT).
   - Cloned the repository to my laptop using the following command:

     ```bash
     git clone http://44.201.4.72/ban898/project.git
     ```

   - Saved the cloned repository to a folder on my laptop.

