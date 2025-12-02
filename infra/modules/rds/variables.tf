variable "name" {}
variable "engine" {}
variable "engine_version" {}
variable "instance_class" {}
variable "username" {}
variable "password" {}
variable "subnet_ids" { type = list(string) }
variable "vpc_security_group_ids" { type = list(string) }
variable "tags" { 
    type = map(string) 
    default = {} 
    }
