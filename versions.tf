terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.18"

      configuration_aliases = [
        aws,
        aws.route53,
        aws.us-east-1,
      ]
    }
  }
  required_version = ">= 1.2.2"
}
