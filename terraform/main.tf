provider "aws" {
    region = "ap-southeast-2"
}

resource "aws_key_pair" "jenkins" {
  key_name   = "jenkins-key"
  public_key = file("~/.ssh/jenkins.pub")
}

resource "aws_security_group" "staging_sg" {
    name = "staging_sg"
    description = "Allow web traffic"
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "staging" {
  ami           = "ami-0a0f4cb8a4cf6819c" # Ubuntu 22.04 LTS in ap-southeast-2
  instance_type = "t2.micro" 
  key_name      = aws_key_pair.jenkins.key_name
  security_groups = [aws_security_group.staging_sg.name]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              usermod -aG docker ubuntu
              EOF

  tags = {
    Name = "ctf-manager-staging"
  }
}