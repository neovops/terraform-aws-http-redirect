module "redirect" {
  source = "../../"

  dns_zone = "neovops.io"

  redirect_mapping = {
    "www.neovops.io"  = "neovops.io",
    "docs.neovops.io" = "neovops.io/docs"
  }

  providers = {
    aws           = aws
    aws.route53   = aws
    aws.us-east-1 = aws.us-east-1
  }
}
