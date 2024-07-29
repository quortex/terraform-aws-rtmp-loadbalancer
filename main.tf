# Network load balancer for rtmp.
resource "aws_lb" "rtmp" {
  name                             = local.lb_name
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = var.subnet_ids
  security_groups                  = [aws_security_group.rtmp_loadbalancer.id]
  enable_cross_zone_load_balancing = var.lb_cross_zone_load_balancing
  idle_timeout                     = var.lb_idle_timeout

  # Store NLB logs in s3
  access_logs {
    enabled = var.access_logs_enabled
    bucket  = aws_s3_bucket.access_logs.bucket
    prefix  = var.access_logs_bucket_prefix
  }

  tags = var.tags
}

resource "aws_lb_target_group" "rtmp" {
  name                   = var.name
  vpc_id                 = var.vpc_id
  port                   = var.rtmp_backend_ingress_port
  protocol               = "TCP"
  connection_termination = var.lb_connection_termination
  deregistration_delay   = var.lb_deregistration_delay
  preserve_client_ip     = false

  target_health_state {
    enable_unhealthy_connection_termination = var.lb_unhealthy_connection_termination
  }

  health_check {
    healthy_threshold   = var.lb_health_check_healthy_threshold
    interval            = var.lb_health_check_interval
    port                = var.rtmp_backend_ingress_port
    protocol            = "TCP"
    timeout             = var.lb_health_check_timeout
    unhealthy_threshold = var.lb_health_check_unhealthy_threshold
  }

  tags = var.tags
}

resource "aws_lb_listener" "rtmp" {
  load_balancer_arn = aws_lb.rtmp.arn
  port              = "1935"
  protocol          = "TCP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rtmp.arn
  }
  tags = var.tags
}

resource "aws_lb_listener" "rtmps" {
  count             = var.rtmps_enabled ? 1 : 0
  load_balancer_arn = aws_lb.rtmp.arn
  port              = "443"
  protocol          = "TLS"
  ssl_policy        = var.lb_ssl_policy
  certificate_arn   = var.create_cert ? aws_acm_certificate.cert[0].arn : var.ssl_certificate_arn
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.rtmp.arn
  }
  tags = var.tags
}

resource "aws_autoscaling_attachment" "rtmp" {
  count                  = var.rtmp_backend_autoscaling_group_name != "" ? 1 : 0
  autoscaling_group_name = var.rtmp_backend_autoscaling_group_name
  lb_target_group_arn    = aws_lb_target_group.rtmp.arn
}

# Common security group configuration
resource "aws_security_group" "rtmp_loadbalancer" {
  name        = local.sg_name
  description = "Security group for the rtmp ELB ${local.lb_name}"
  vpc_id      = var.vpc_id

  tags = merge({
    Name = local.sg_name
    },
    var.tags
  )
}

resource "aws_security_group_rule" "rtmp_loadbalancer_ingress_rtmp" {
  count             = length(var.lb_ingress_cidr_blocks_rtmp) > 0 ? 1 : 0
  description       = "Allow RTMP ingress"
  type              = "ingress"
  from_port         = 1935
  to_port           = 1935
  protocol          = "tcp"
  cidr_blocks       = var.lb_ingress_cidr_blocks_rtmp
  security_group_id = aws_security_group.rtmp_loadbalancer.id
}

resource "aws_security_group_rule" "rtmp_loadbalancer_ingress_rtmps" {
  count             = length(var.lb_ingress_cidr_blocks_rtmps) > 0 ? 1 : 0
  description       = "Allow RTMPS ingress"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = var.lb_ingress_cidr_blocks_rtmps
  security_group_id = aws_security_group.rtmp_loadbalancer.id
}

resource "aws_security_group_rule" "rtmp_loadbalancer_egress" {
  description       = "Allow all traffic out"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "all"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.rtmp_loadbalancer.id
}

# ELB backend ingress permissions
resource "aws_security_group_rule" "rtmp_ingress" {
  description       = "Allow access to the rtmp ingress port from the VPC"
  security_group_id = var.rtmp_backend_security_group_id
  protocol          = "tcp"
  type              = "ingress"
  from_port         = var.rtmp_backend_ingress_port
  to_port           = var.rtmp_backend_ingress_port
  cidr_blocks       = [var.vpc_cidr]
}

# ELB access logs bucket configuration
resource "aws_s3_bucket" "access_logs" {
  bucket        = var.access_logs_bucket_name != "" ? var.access_logs_bucket_name : "${var.name}-access-logs"
  force_destroy = var.access_logs_force_destroy

  tags = var.tags
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs" {
  count = var.access_logs_expiration != null ? 1 : 0

  bucket = aws_s3_bucket.access_logs.id
  rule {
    id     = "expiration"
    status = "Enabled"
    expiration {
      days = var.access_logs_expiration
    }
  }
}

resource "aws_s3_bucket_public_access_block" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Set minimal encryption on buckets
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  count  = var.enable_bucket_encryption ? 1 : 0
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${aws_s3_bucket.access_logs.bucket}/*",
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      },
      {
        Effect = "Allow",
        Principal = {
          Service = "delivery.logs.amazonaws.com"
        },
        Action   = "s3:GetBucketAcl",
        Resource = "arn:aws:s3:::${aws_s3_bucket.access_logs.bucket}"
      }
    ]
  })
}

# DNS record alias that target the load balancer
resource "aws_route53_record" "rtmp" {
  zone_id = var.dns_hosted_zone_id
  name    = var.dns_record
  type    = "A"

  alias {
    name                   = aws_lb.rtmp.dns_name
    zone_id                = aws_lb.rtmp.zone_id
    evaluate_target_health = false
  }
}

# Certificate in AWS Certificate Manager
resource "aws_acm_certificate" "cert" {
  count             = var.create_cert ? 1 : 0
  domain_name       = var.ssl_certificate_domain_name
  validation_method = "DNS"

  tags = merge({
    Name = local.cert_name
    },
    var.tags
  )

  lifecycle {
    create_before_destroy = true
  }
}

# DNS record to validate this certificate
resource "aws_route53_record" "cert_validation" {
  count   = var.create_cert ? 1 : 0
  name    = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_name
  type    = tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_type
  zone_id = var.dns_hosted_zone_id
  records = [tolist(aws_acm_certificate.cert[0].domain_validation_options)[0].resource_record_value]
  ttl     = 60
}

# Certificate validation
resource "aws_acm_certificate_validation" "cert" {
  count                   = var.create_cert ? 1 : 0
  certificate_arn         = aws_acm_certificate.cert[0].arn
  validation_record_fqdns = [aws_route53_record.cert_validation[0].fqdn]
}
