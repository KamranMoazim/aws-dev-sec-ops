moved {
  from = module.secrets
  to   = module.environment.module.secrets
}

moved {
  from = module.network
  to   = module.environment.module.network
}

moved {
  from = module.rds
  to   = module.environment.module.rds
}

moved {
  from = module.app
  to   = module.environment.module.app
}

moved {
  from = aws_ssm_parameter.image_tag
  to   = module.environment.aws_ssm_parameter.image_tag
}

moved {
  from = aws_acm_certificate.app
  to   = module.environment.aws_acm_certificate.app
}

moved {
  from = aws_route53_record.app_validation
  to   = module.environment.aws_route53_record.app_validation
}

moved {
  from = aws_acm_certificate_validation.app
  to   = module.environment.aws_acm_certificate_validation.app
}

moved {
  from = aws_route53_record.app
  to   = module.environment.aws_route53_record.app
}
