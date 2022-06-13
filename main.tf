/**
 * [![Neovops](https://neovops.io/images/logos/neovops.svg)](https://neovops.io)
 *
 * # Terraform AWS HTTP Redirect
 *
 * Terraform module to create http 302 redirection.
 *
 * This module creates:
 *  * a CloudFront distribution for all redirections
 *  * a CloudFront function for all redirections
 *  * an ACM certificate for all redirections
 *  * route53 record for each domain
 *
 *
 * ## Terraform registry
 *
 * This module is available on
 * [terraform registry](https://registry.terraform.io/modules/neovops/http-redirect/aws/latest).
 *
 *
 * ## Requirements
 *
 * The Route53 zone must already exists.
 *
 *
 * ## Providers
 *
 * This module needs 3 providers:
 *  * aws - default provider for resources
 *  * aws.route53 - Where route53 zones already exist
 *  * aws.us-east-1 same account as `aws`, for acm certificate
 *
 *  This handle the use case where multiple aws accounts are used but it can be
 *  the same provider.
 *
 * ## Examples
 *
 * ### Simple
 *
 * ```hcl
 *
 * provider "aws" {
 *   region = "eu-west-1"
 * }
 *
 * provider "aws" {
 *   alias  = "us-east-1"
 *   region = "us-east-1"
 * }
 *
 * resource "aws_route53_zone" "neovops_io" {
 *   name = "neovops.io"
 * }
 *
 * module "http-redirect" {
 *   source = "neovops/http-redirect/aws"
 *
 *   redirect_mapping = {
*      "www.neovops.io" = "neovops.io",
*      "docs.neovops.io" = "neovops.io/docs"
 *   }
 *
 *   dns_zone = aws_route53_zone.neovops_io.name
 *
 *   providers = {
 *     aws           = aws
 *     aws.route53   = aws
 *     aws.us-east-1 = aws.us-east-1
 *   }
 * }
 * ```
 */

data "aws_route53_zone" "zone" {
  name = var.dns_zone

  provider = aws.route53
}


# ACM

resource "aws_acm_certificate" "cert" {
  domain_name               = keys(var.redirect_mapping)[0]
  validation_method         = "DNS"
  subject_alternative_names = slice(keys(var.redirect_mapping), 1, length(var.redirect_mapping))

  provider = aws.us-east-1
}

resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  name    = each.value.name
  records = [each.value.record]
  type    = each.value.type
  zone_id = data.aws_route53_zone.zone.zone_id
  ttl     = 60

  provider = aws.route53
}

resource "aws_acm_certificate_validation" "cert" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]

  provider = aws.us-east-1
}

# CloudFront

resource "aws_cloudfront_function" "redirect" {
  name    = var.resources_name
  runtime = "cloudfront-js-1.0"
  comment = "HTTP redirect"
  publish = true
  code = templatefile("${path.module}/redirect.js", {
    redirect_mapping = jsonencode(var.redirect_mapping)
  })
}

resource "aws_cloudfront_distribution" "distribution" {
  origin {
    domain_name = "dev.null"
    origin_id   = "null"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "match-viewer"
      origin_ssl_protocols   = ["TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }


  enabled = true

  default_cache_behavior {
    viewer_protocol_policy = "redirect-to-https"
    compress               = true
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "null"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.redirect.arn
    }
  }

  aliases = keys(var.redirect_mapping)

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  depends_on = [
    aws_acm_certificate_validation.cert,
  ]
}


# DNS

resource "aws_route53_record" "main" {
  for_each = toset(keys(var.redirect_mapping))

  zone_id = data.aws_route53_zone.zone.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.distribution.domain_name
    zone_id                = aws_cloudfront_distribution.distribution.hosted_zone_id
    evaluate_target_health = true
  }

  provider = aws.route53
}
