locals {
  lb_name   = var.lb_name != "" ? var.lb_name : var.name
  sg_name   = var.lb_security_group_name != "" ? var.lb_security_group_name : "${var.name}-elb"
  cert_name = var.ssl_certificate_name != "" ? var.ssl_certificate_name : var.name
}
