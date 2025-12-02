# same variables and resource as asg_frontend
variable "name" {}
variable "launch_template_id" {}
variable "subnet_ids" { type = list(string) }
variable "desired_capacity" { default = 1 }
variable "min_size" { default = 1 }
variable "max_size" { default = 2 }
variable "alb_target_group_arn" {}
variable "tags" { 
    type = map(string) 
    default = {} 
    }

resource "aws_autoscaling_group" "this" {
  name = var.name
  desired_capacity = var.desired_capacity
  min_size = var.min_size
  max_size = var.max_size

  launch_template {
    id = var.launch_template_id
    version = "$Latest"
  }

  vpc_zone_identifier = var.subnet_ids
  target_group_arns = [var.alb_target_group_arn]

  tag {
    key = "Name"
    value = var.name
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

output "asg_name" { value = aws_autoscaling_group.this.name }
