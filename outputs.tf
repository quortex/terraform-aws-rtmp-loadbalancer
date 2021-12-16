output "dns_record" {
  description = "The DNS record for the RTMP endpoint"
  value       = aws_route53_record.rtmp.fqdn
}
