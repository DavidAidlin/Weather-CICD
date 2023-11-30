provider "aws" {
  region = "us-east-1"  
}

resource "aws_key_pair" "deployer_key" {
  key_name   = "my-aws-key"
  public_key = file("${path.module}/my-aws-key.pub")
}


resource "aws_instance" "gitlab_server" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.xlarge"
  key_name      = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  subnet_id     = aws_subnet.my_subnet.id
  tags = {
    Name = "GitLab Server"
  }
}

resource "aws_ebs_volume" "gitlab_server_extra_volume" {
  availability_zone = aws_instance.gitlab_server.availability_zone
  size              = 20
  type              = "gp2"

  tags = {
    Name = "GitLab Server Extra Volume"
  }
}

resource "aws_volume_attachment" "gitlab_server_extra_volume_attachment" {
  device_name = "/dev/sdh"
  volume_id   = aws_ebs_volume.gitlab_server_extra_volume.id
  instance_id = aws_instance.gitlab_server.id
  force_detach = true
}

resource "aws_instance" "jenkins_master" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.xlarge"
  key_name      = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  subnet_id     = aws_subnet.my_subnet.id

  tags = {
    Name = "Jenkins Master"
  }
}

resource "aws_instance" "jenkins_agent" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  subnet_id     = aws_subnet.my_subnet.id

  tags = {
    Name = "Jenkins Agent"
  }
}

resource "aws_instance" "deployment_server" {
  ami           = "ami-06aa3f7caf3a30282"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.deployer_key.key_name
  vpc_security_group_ids = [aws_security_group.common_sg.id]
  subnet_id     = aws_subnet.my_subnet.id

  tags = {
    Name = "Deployment Server"
  }
}

