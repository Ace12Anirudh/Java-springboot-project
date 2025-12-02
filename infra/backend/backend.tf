terraform {
  required_version = ">= 1.0"

  backend "s3" {
    bucket         = "jenkins-terraform-s3-ace-bucket"        # <-- create first or change to your bucket
    key            = "java-springboot-project/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"   # <-- create or change
    encrypt        = true
  }
}
