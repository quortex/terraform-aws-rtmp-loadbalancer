locals {
  elb_name  = var.elb_name != "" ? var.elb_name : var.name
  sg_name   = var.elb_security_group_name != "" ? var.elb_security_group_name : "${var.name}-elb"
  cert_name = var.ssl_certificate_name != "" ? var.ssl_certificate_name : var.name
}
