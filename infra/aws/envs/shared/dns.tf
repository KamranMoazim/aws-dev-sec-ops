resource "aws_route53_zone" "this" {
  #checkov:skip=CKV2_AWS_38:DNSSEC needs a DS record at the external registrar; added with the security baseline
  #checkov:skip=CKV2_AWS_39:Query logging is enabled with the security baseline step
  count = local.dns_enabled ? 1 : 0

  name    = var.dns_zone_name
  comment = "Delegated from the registrar via NS records"
}

locals {
  dns_enabled = try(length(var.dns_zone_name) > 0, false)
}
