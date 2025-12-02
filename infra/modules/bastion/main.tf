variable "name" {}
variable "ami_id" {}
variable "instance_type" {}
variable "key_name" {}
variable "subnet_id" {}
variable "security_group_id" {}
variable "user_data_template" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
    }

resource "aws_instance" "bastion" {
  ami = var.ami_id
  instance_type = var.instance_type
  subnet_id = var.subnet_id
  key_name = var.key_name
  associate_public_ip_address = true
  vpc_security_group_ids = [var.security_group_id]
  user_data = base64encode(var.user_data_template)
  tags = merge(var.tags, { Name = var.name })
}

output "bastion_public_ip" { value = aws_instance.bastion.public_ip }
