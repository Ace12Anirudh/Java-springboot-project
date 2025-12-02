variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "tags" { 
    type = map(string) 
    default = {} 
    }
