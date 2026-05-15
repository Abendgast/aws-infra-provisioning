
resource "aws_route53_zone" "public" {
  name = "contoso.com"
}

resource "aws_route53_record" "www" {
  zone_id = aws_route53_zone.public.zone_id
  name    = "www.contoso.com"
  type    = "A"
  ttl     = 300
  records = ["10.1.1.4"] # Placeholder IP to match Azure Lab spec
}

resource "aws_route53_zone" "private" {
  name = "private.contoso.com"
  vpc {
    vpc_id = aws_vpc.mfg.id
  }
}

resource "aws_route53_record" "sensorvm" {
  zone_id = aws_route53_zone.private.zone_id
  name    = "sensorvm.private.contoso.com"
  type    = "A"
  ttl     = 300
  records = [aws_instance.mfg_vm.private_ip]
}
