resource "aws_acm_certificate" "chrisbarm_cert01" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
}

resource "aws_route53_record" "chrisbarm_cert_validation_records01" {
  for_each = {
    for dvo in aws_acm_certificate.chrisbarm_cert01.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = local.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
  allow_overwrite = true
}

resource "aws_acm_certificate_validation" "chrisbarm_cert_validation01" {
  certificate_arn = aws_acm_certificate.chrisbarm_cert01.arn
  validation_record_fqdns = [
    for record in aws_route53_record.chrisbarm_cert_validation_records01 : record.fqdn
  ]
}
