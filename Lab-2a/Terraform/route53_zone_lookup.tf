data "aws_route53_zone" "selected" {
  name         = var.domain_name
  private_zone = false
}

locals {
  route53_zone_id = can(regex("^Z", var.route53_zone_id)) ? var.route53_zone_id : data.aws_route53_zone.selected.zone_id
}
