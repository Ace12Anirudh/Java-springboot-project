variable "name" {}
variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "frontend_target_group_port" { default = 80 }
variable "backend_target_group_port" { default = 8080 }
variable "tags" { 
    type = map(string) 
    default = {} 
    }

resource "aws_lb" "alb" {
  name = "${var.name}-alb"
  internal = false
  load_balancer_type = "application"
  subnets = var.public_subnet_ids
  tags = var.tags
}

resource "aws_lb_target_group" "frontend_tg" {
  name = "stud-mgmt-frontend-tg"
  port = var.frontend_target_group_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    path = "/"
    protocol = "HTTP"
    matcher = "200-399"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "backend_tg" {
  name = "stud-mgmt-backend-tg"
  port = var.backend_target_group_port
  protocol = "HTTP"
  vpc_id = var.vpc_id
  health_check {
    path = "/student/health"
    protocol = "HTTP"
    matcher = "200-399"
    interval = 30
    timeout = 5
    healthy_threshold = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code = "404"
    }
  }
}

resource "aws_lb_listener_rule" "backend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.backend_tg.arn
  }
  condition {
    path_pattern {
      values = ["/student/*", "/actuator/*"]
    }
  }
}

resource "aws_lb_listener_rule" "frontend_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority = 200
  action {
    type = "forward"
    target_group_arn = aws_lb_target_group.frontend_tg.arn
  }
  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

output "alb_dns" { value = aws_lb.alb.dns_name }
output "frontend_tg_arn" { value = aws_lb_target_group.frontend_tg.arn }
output "backend_tg_arn" { value = aws_lb_target_group.backend_tg.arn }
