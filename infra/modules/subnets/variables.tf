variable "vpc_id" {}
variable "azs" { type = list(string) }
variable "public_cidrs" { type = list(string) }
variable "private_cidrs" { type = map(list(string)) }
variable "tags" { 
    type = map(string) 
    default = {} 
    }
