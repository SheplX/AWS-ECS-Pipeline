data "aws_route53_zone" "ecs_hosted_zone" {
  name = var.hosted_zone
}

resource "aws_route53_record" "ecs_route53_record" {
  depends_on              = [var.alb]
  name                    = var.record_name
  type                    = "A"
  zone_id                 = data.aws_route53_zone.ecs_hosted_zone.zone_id

  alias {
    evaluate_target_health = true
    name                   = var.alb.dns_name
    zone_id                = var.alb.zone_id
  }
}