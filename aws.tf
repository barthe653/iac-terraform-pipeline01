data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = [099720109477]
}

resource "aws_vpc" "vpc" {
  cidr_block = "172.16.8.0/16"

  tags = {
    Name = "web-server-vpc"
  }
}

resource "aws_subnet" "subnet" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "${var.aws_region}a"

  tags = {
    Name = "web-server-subnet"
  }
}

resource "aws_security_group" "web-server-sg" {
  name = "web-server-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "server-web" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-server-sg.id]
  user_data              = <<-EOF

                  #!/bin/bash
                  apt-get update
                  apt-get install -y apache2
                  sed -i -e 's/86/8688/ /etc/apache2/ports.conf
                  currentDateTime=$(date)
                  echo "Hello AWS Terraform github Actions CI/CD Pipeline Demo $currentDateTime" > /var/www/html/index.html "
                  systemctl restart apache2
                  EOF
  tags = {
    Name = "web-server"
  }
}



##module "web-server-app" {
##source                = "./modules/aws/web-server"
##aws-owners            = [var.aws-owners]
##aws_region            = var.aws_region
##instance_type         = "t2.micro"
##server_name           = "web-server-app"
##vpc_cidr_block        = "11.10.0.0/16"
##vpc_subnet_cidr_block = "11.10.1.0/28"
##web_server_port       = "8081"
##}
