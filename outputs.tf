output "core_vpc_id" {
  value = aws_vpc.core.id
}

output "mfg_vpc_id" {
  value = aws_vpc.mfg.id
}

output "alb_dns_name" {
  value = aws_lb.main.dns_name
}

output "s3_bucket_name" {
  value = aws_s3_bucket.main.id
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.main.name
}
