output "dns_record" {
  description = "The DNS record for the RTMP endpoint"
  value       = aws_route53_record.rtmp.fqdn
}

output "lb_target_group_arn" {
  value       = aws_lb_target_group.rtmp.arn
  description = "The ARN of the target group of the RTMP load balancer."
}
