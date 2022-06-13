[![Neovops](https://neovops.io/images/logos/neovops.svg)](https://neovops.io)

# Terraform AWS HTTP Redirect

Terraform module to create http 302 redirection.

This module creates:
 * a CloudFront distribution for all redirections
 * a CloudFront function for all redirections
 * an ACM certificate for all redirections
 * route53 record for each domain

## Terraform registry

This module is available on
[terraform registry](https://registry.terraform.io/modules/neovops/http-redirect/aws/latest).

## Requirements

The Route53 zone must already exists.

## Providers

This module needs 3 providers:
 * aws - default provider for resources
 * aws.route53 - Where route53 zones already exist
 * aws.us-east-1 same account as `aws`, for acm certificate

 This handle the use case where multiple aws accounts are used but it can be
 the same provider.

## Examples

### Simple

```hcl

provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

resource "aws_route53_zone" "my_website_com" {
  name = "my-website.com"
}

module "http-redirect" {
  source = "neovops/http-redirect/aws"

  redirect_mapping = {
     "www.neovops.io" = "neovops.io",
     "docs.neovops.io" = "neovops.io/docs"
  }

  dns_zone = "neovops.io"

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.2 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.18 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | ~> 4.18 |
| <a name="provider_aws.route53"></a> [aws.route53](#provider\_aws.route53) | ~> 4.18 |
| <a name="provider_aws.us-east-1"></a> [aws.us-east-1](#provider\_aws.us-east-1) | ~> 4.18 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_route53_record.cert_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_zone.zone](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_dns_zone"></a> [dns\_zone](#input\_dns\_zone) | Route53 DNS zone name | `string` | n/a | yes |
| <a name="input_redirect_mapping"></a> [redirect\_mapping](#input\_redirect\_mapping) | Redirect mapping | `map(string)` | n/a | yes |
| <a name="input_resources_name"></a> [resources\_name](#input\_resources\_name) | Resources name. Necessary for multiple instances of this module | `string` | `"http-redirect"` | no |

## Outputs

No outputs.
