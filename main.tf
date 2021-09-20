provider "aws" {
  profile = "default"
  region  = var.region
}

resource "aws_vpc" "srv_vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = "jenkins_srv"
  }
}

resource "aws_subnet" "srv_subnet" {
  vpc_id            = aws_vpc.srv_vpc.id
  cidr_block        = var.cidr_block
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "subnet terraform"
  }
}

resource "aws_internet_gateway" "srv_igw"{
  vpc_id = aws_vpc.srv_vpc.id
}

resource "aws_route_table" "my_route_table" {
    vpc_id = "${aws_vpc.srv_vpc.id}"
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = "${aws_internet_gateway.srv_igw.id}"
    }

}

resource "aws_route_table_association" "my_route_table_assoc" {
    subnet_id = "${aws_subnet.srv_subnet.id}"
    route_table_id = "${aws_route_table.my_route_table.id}"
}
resource "aws_security_group" "srv_security_group" {
  name   = "srv_security_group"
  vpc_id = aws_vpc.srv_vpc.id

  ingress = [
    {
      description      = "security group inbound rule for SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self = null
      prefix_list_ids= null
      security_groups=null
    },
    {
      description      = "security group inbound rule for Jenkins"
      from_port   = 8080
      to_port     = 8080
      protocol    = "TCP"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self = null
      prefix_list_ids= null
      security_groups= null
    }
  ]
  egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
      self = null
      prefix_list_ids= null
      security_groups= null
      description = "security group outbound rule"

    }
  ]

  tags = {
    Name = "srv_security_group"
  }
}


resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC5dnX6Ne4nA+DY4coycZsHDu/0zObwDicWSFCci8V+F0GyMxGPFr3o7knLcXy7Js546BwxmU+g7qht4slqxudHmFrASklzM08fbslJwM9mvMjKUf62VoMpzuLb2mJ/RBOTGd6zdCsViVHHpoqMDcYtlB9ZNNwfpv5LzbHlpei6K2pGp6d4hHJBG+wM1URpamC3mafvRCs6rAEz6U+n7nkQsI9Lx5zFiv/ZBoj1X58eWNzuAJoySvKHP2MHo3l8j6rL8z64V/l18BZwhY1cdVrS1AYy9pZkfpyeSB4uWssZX4yYfXA+LV6qjeB0I3fZHpjpiLEowFWQapRqU9plhzuwGIo5mvs6HpQBvxSEld+rTPHOsnQ3MO/QwIRpfwtVFXiEnYERQeuLgRlxA0hcyucrn9iQ1V4v5j1Lnm0dNs5nE2FanrawfcdhQuj68fd0k7qLDgwZOM+SkPKo8Ym5rGMhwtWElINaFDIKvO5Wg9w5PegCO5s+5owZc6WitAOCDhE= aweiss@isml-aweiss"
}
resource "aws_instance" "master" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = var.machine_type
  associate_public_ip_address = "true"
  subnet_id = aws_subnet.srv_subnet.id
  vpc_security_group_ids = [aws_security_group.srv_security_group.id]
  key_name = aws_key_pair.deployer.key_name
  tags = {
    Name = "jenkins master "
  }
}

resource "aws_instance" "slave" {
  ami           = "ami-09e67e426f25ce0d7"
  instance_type = var.machine_type
  associate_public_ip_address = "true"
  subnet_id = aws_subnet.srv_subnet.id
  vpc_security_group_ids = [aws_security_group.srv_security_group.id]
  key_name = aws_key_pair.deployer.key_name

  tags = {
    Name = "jenkins slave "
  }
}