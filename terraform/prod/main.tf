provider "aws" {
    region = "ap-southeast-2"
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-key"
  public_key = file("~/.ssh/jenkins.pub")
}

resource "aws_security_group" "prod_sg" {
    name = "prod_sg"
    description = "Allow web traffic"
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
        description = "SSH from Jenkins"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "prod_app_server" {
  ami           = "ami-0279a86684f669718" # Ubuntu 24.04 LTS in ap-southeast-2
  instance_type = "t3.micro" 

  key_name      = aws_key_pair.jenkins.key_name
  security_groups = [aws_security_group.prod_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io unzip curl
              curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
              unzip awscliv2.zip
              ./aws/install
              apt-get install -y docker-compose-v2
              usermod -aG docker ubuntu
              EOF
  
  root_block_device {
    volume_size = 12   
    volume_type = "gp3"
  }

  tags = {
    Name = "ctf-manager-prod"
  }
}

output "public_ip" {
  value = aws_instance.prod_app_server.public_ip
}