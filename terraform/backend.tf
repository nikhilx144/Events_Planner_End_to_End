terraform {
  backend "s3" {
    bucket = "nikhil-events-planner-terraform-state-bucket"
    key = "terraform.tfstate"
    region = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt = true
  }
}
