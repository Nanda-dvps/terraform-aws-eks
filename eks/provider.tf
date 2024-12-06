terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.75.0"
    }
  }

  backend "s3" {
    bucket = "remote-state-expense"
    key    = "expense-eks"
    region = "us-east-1"
    dynamodb_table = "locking"
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}