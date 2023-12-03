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

