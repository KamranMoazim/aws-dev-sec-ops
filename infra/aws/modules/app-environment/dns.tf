locals {
  dns_enabled = try(length(var.dns_zone_name) > 0, false)
  app_fqdn    = local.dns_enabled ? "${var.hostname}.${var.dns_zone_name}" : null
}

data "aws_route53_zone" "this" {
  count    = local.dns_enabled ? 1 : 0
  provider = aws.dns

  name         = var.dns_zone_name
  private_zone = false
}

resource "aws_acm_certificate" "app" {
  count = local.dns_enabled ? 1 : 0

  domain_name       = local.app_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "app_validation" {
  for_each = local.dns_enabled ? {
    for option in aws_acm_certificate.app[0].domain_validation_options : option.domain_name => option
  } : {}
  provider = aws.dns

  zone_id         = data.aws_route53_zone.this[0].zone_id
  name            = each.value.resource_record_name
  type            = each.value.resource_record_type
  records         = [each.value.resource_record_value]
  ttl             = 300
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "app" {
  count = local.dns_enabled ? 1 : 0

  certificate_arn         = aws_acm_certificate.app[0].arn
  validation_record_fqdns = [for record in aws_route53_record.app_validation : record.fqdn]
}

resource "aws_route53_record" "app" {
  count    = local.dns_enabled ? 1 : 0
  provider = aws.dns

  zone_id = data.aws_route53_zone.this[0].zone_id
  name    = local.app_fqdn
  type    = "A"

  alias {
    name                   = module.app.alb_dns_name
    zone_id                = module.app.alb_zone_id
    evaluate_target_health = true
  }
}
