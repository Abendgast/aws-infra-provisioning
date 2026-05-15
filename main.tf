terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      "Cost Center" = "000"
      "Project"     = "AZ-104-to-AWS"
    }
  }
}

provider "aws" {
  alias  = "dr"
  region = var.aws_region_dr
  default_tags {
    tags = {
      "Cost Center" = "000"
      "Project"     = "AZ-104-to-AWS"
    }
  }
}
