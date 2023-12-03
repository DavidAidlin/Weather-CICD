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
   - Installed the suggested plugins.
   - Created a New User.
   - Installed more plugins, like Credentials, Slack, Git, Email, and more.
   - Configured the necessary credentials Private keys for my EC2 instances docker credentials Email token and slack token.
   - Created a Job of type Pipeline 
   - In the Job Configuration I applied the URL of my GitLab repository
   - Configured the Job to trigger on push events from GitLab webhook 
   - Configured the Job to serach for the JenkinsFile from the same repository
   Here is the JenkinsFile:
   ```
  agent {
    label 'slave'
}

environment {
    DOCKERHUB_CREDENTIALS = credentials('5529ce44-3db2-4dfb-a84e-1734c4102110')
}

stages {
    stage('SCM') {
        steps {
            git branch: 'main', 
                credentialsId: '7e7d1eab-7393-4e82-a672-921736693f98', 
                url: 'http://172.31.6.13/ban898/advanced'
        }
    }

    stage('Build') {
        steps {
            script {
            	sh "docker compose -f docker-compose-delivery.yml up -d"
            }
        }
    }

    stage('Testing') {
        steps {
            script {
                def pytestCommand = '/home/ubuntu/.local/bin/pytest'
                def pytestExitCode = sh script: pytestCommand, returnStatus: true
                if (pytestExitCode == 0) {
                    echo "Pytest passed. Proceeding with pushing the image."
                    currentBuild.result = 'SUCCESS'
                    slackSend(channel: '#devops-alerts', message: 'Pytest SUCCESS', color: 'good')
                } else {
                    echo "Pytest failed. Skipping image push."
                    currentBuild.result = 'FAILURE'
                    slackSend(channel: '#devops-alerts', message: 'Pytest failed!', color: 'danger')
                }
            }
        }
    }
    stage('Delivery') {
    steps {
        sh 'echo $DOCKERHUB_CREDENTIALS_PSW | sudo docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin'

        script {
            def NginxExitCode = sh script: 'sudo docker push ban898/app:Nginx', returnStatus: true
            def AppExitCode = sh script: 'sudo docker push ban898/app:Gunicorn_And_Python', returnStatus: true
            if (NginxExitCode == 0 && AppExitCode == 0) {
                slackSend(channel: '#succeeded-build', message: 'Image was successfully pushed!', color: 'good')
            } else {
                slackSend(channel: '#devops-alerts', message: 'Image push failed!', color: 'danger')
                currentBuild.result = 'FAILURE'
            	}
           }
    	}
    }


    stage('Deploy') {
        steps {
            withCredentials([sshUserPrivateKey(credentialsId: 'Slave Private Key', keyFileVariable: 'SSH_KEY')]) {
                sh '''
                scp docker-compose-deploy.yml ec2-user@172.31.27.196:/home/ec2-user/
                ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@172.31.27.196 'sudo yum update -y; sudo amazon-linux-extras install docker -y; sudo service docker start; sudo 		usermod -a -G docker ec2-user'
                ssh -o StrictHostKeyChecking=no -i $SSH_KEY ec2-user@172.31.27.196 'sudo docker compose up -d --name 'WEB''
                '''
            }
        }
    }
    
    stage('Clean') {
      steps {
          script {
              sh "docker system prune -af"
              sh "docker compose down"
              cleanWs()
          }
      }
    }
}

   ```

**Then SSHed back to the GitLab Instance:**

   - Using GitLab Integrations feature Created a webhook and provided the Jenkins Master URL 
   - Tested the connection and approved it.

**Then SSHed to the Jenkins Agent Instance:**

   - Used the following commands:
   ```
   sudo apt-get update
   sudo apt install -y --no-install-recommends openjdk-17-jdk-headless
   ```  

    - Created a user for jenkins:  

   ```
   sudo adduser --group --home /home/jenkins --shell /bin/bash jenkins
   ```
    - Added required dependencies to the docker-ce repo and a GPG-key :
   ```
   sudo apt-get install ca-certificates curl gnupg lsb-release
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   echo \
   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```
    - Then installed updated and installed Docker-CE
   ```
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```
    - Added the jenkins user to the relevant groups
   ```
   sudo usermod -aG docker jenkins
   sudo usermod -aG sudo jenkins  

    - In the Jenkins web UI navigated to manage nodes and cloud 
    - New Node -> Assigned it a Name  
    - Number of executors: Set how many executors will be available on the Node (Best practice is to set it equal to the number of CPU cores on the Agent)
    - Under Remote root directory I used /home/jenkins
    - Under the Label field I used Agent.
    - For the Usage now I chose Use this node as much as possible. 
    - I chose Launch agent by connecting it to the controller. That means that you will have to launch the agent on the node itself and that the agent will then connect to the controller

