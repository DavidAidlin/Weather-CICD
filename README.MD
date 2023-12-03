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

```
```

Then I Created an SSH key using
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

To install Docker and add the relevant user as a user with the right permissions

