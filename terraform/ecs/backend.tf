terraform {
  backend "s3" {
    profile = "test"
    bucket  = "terraform-state-wtfender"
    key     = "terraform-states/wp-ecs.tfstate"
    region  = "us-west-2"
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 2.70"
    }
  }
}