variable "vpc_id" {}
variable "public_subnet_ids" { type = list(string) }
variable "private_app_subnet_ids" { 
  type = map(string)
  description = "Map of private app subnet IDs"
}
variable "private_db_subnet_ids" { 
  type = map(string)
  description = "Map of private db subnet IDs"
}
variable "tags" { 
    type = map(string) 
    default = {} 
    }

