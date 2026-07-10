# key pair login 
resource "aws_key_pair" "my_key" {
    key_name = "terr-key-ec2"
    public_key = file("terr-key-ec2.pub")
}


# VPS & Security Group
resource "aws_default_vpc" "default" {
  
}

resource "aws_security_group" "my_security" {
    name = "automate-sg"
    description = "this will add a tf generated security group"
    vpc_id = aws_default_vpc.default.id # interpolation

    # inbound rules
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "SSH open"
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Http port open"
    }
    ingress {
        from_port = 8000
        to_port = 8000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "Custom port" 
    }

    # outbound rules
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"  # this is for all protcol
        cidr_blocks = ["0.0.0.0/0"]
        description = "All access open outbound"
    }
}


#   ec2 instance

resource "aws_instance" "my_instance" {
    key_name = aws_key_pair.my_key.key_name
    security_groups = [aws_security_group.my_security.name]
    instance_type = var.ec2_instance_type
    ami = var.ec2_ami_id # ubuntu
    user_data = file("install_ngnix.sh")
    root_block_device {
      volume_type = var.ec2_root_storage_type
      volume_size = var.ec2_root_storage_size
    }
    
    tags = {
        Name =  var.ec2_instance_name
    }
}