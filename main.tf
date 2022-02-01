provider "aws" {
  region     = "ap-south-1"
  access_key = ""
  secret_key = ""
}

resource "aws_vpc" "vpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_support = "true"

  tags = {
    Name = "project"

  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "projrct_igw"
  }
}

# route tables

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}



#public subnets

resource "aws_subnet" "subnets" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "public_subnet"


  }
}
resource "aws_route_table_association" "public-rt-ass" {
  subnet_id      = element(aws_subnet.subnets.*.id, count.index)
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "allow_all" {
  name        = "allow_all"
  description = "Allow all inbound traffic"
  vpc_id      = "${aws_vpc.vpc.id}"

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    }
}

resource "aws_instance" "web-1" {

    ami = "ami-083654bd07b5da81d"
    instance_type = "t2.micro"
    key_name = "nani"
    subnet_id = aws_subnet.subnets.id
    vpc_security_group_ids = ["${aws_security_group.allow_all.id}"]
    associate_public_ip_address = true
    tags = {
        Name = "httpd"

    }

}

resource "null_resource" "ssh_connection" {
depends_on = [aws_instance.web-1]



connection {
    type     = "ssh"
    user     = "ubuntu"
    private_key  = file("nani.pem")
    host        = aws_instance.web-1.public_ip
 }

provisioner "file" {
  source      = "web.sh"
  destination = "/home/ubuntu/web.sh"

  }


provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /home/ubuntu/web.sh",
      "sh /home/ubuntu/web.sh",
      "mkdir ok",


    ]
}
provisioner "file" {
  source      = "script.sh"
  destination = "/home/ubuntu/script.sh"

  }


provisioner "remote-exec" {
    inline = [
      "sudo chmod 777 /home/ubuntu/script.sh",
      "sh /home/ubuntu/script.sh",
      


    ]
}

}
