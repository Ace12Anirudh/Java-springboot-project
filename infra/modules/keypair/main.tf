variable "key_name" { type = string }
variable "public_key" { type = string }

resource "aws_key_pair" "this" {
  key_name   = var.key_name
  public_key = var.public_key
}

output "key_name" { value = aws_key_pair.this.key_name }
