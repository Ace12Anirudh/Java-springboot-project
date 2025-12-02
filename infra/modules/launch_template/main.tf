variable "name" {}
variable "instance_type" {}
variable "ami_id" {}
variable "key_name" {}
variable "iam_instance_profile" {}
variable "security_group_ids" { type = list(string) }
variable "user_data_template" { type = string }
variable "tags" { 
    type = map(string) 
    default = {} 
    }

resource "aws_launch_template" "this" {
  name_prefix = "${var.name}-lt-"
  image_id = var.ami_id
  instance_type = var.instance_type
  key_name = var.key_name

  iam_instance_profile {
    name = var.iam_instance_profile
  }

  network_interfaces {
    security_groups = var.security_group_ids
    associate_public_ip_address = false
  }

  user_data = base64encode(var.user_data_template)
  tag_specifications {
    resource_type = "instance"
    tags = merge(var.tags, { Name = var.name })
  }
}

output "launch_template_id" { value = aws_launch_template.this.id }
