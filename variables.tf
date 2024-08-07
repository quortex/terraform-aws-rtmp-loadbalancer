variable "name" {
  type        = string
  description = "A name from which the name of the resources will be chosen. Note that each resource name can be set individually."
}

variable "vpc_id" {
  type        = string
  description = "ID of the VPC in which the resources should be deployed."
}

variable "vpc_cidr" {
  type        = string
  description = "The CIDR for the VPC."
}

variable "subnet_ids" {
  type        = list(string)
  description = "The IDs of the subnets where resources should be placed."
  default     = []
}

variable "lb_name" {
  type        = string
  description = "Override the ELB name."
  default     = ""
}

variable "lb_cross_zone_load_balancing" {
  type        = bool
  description = "Enable cross-zone load balancing."
  default     = false
}

variable "lb_idle_timeout" {
  type        = number
  description = "The time in seconds that the connection is allowed to be idle."
  default     = 60
}

variable "lb_connection_termination" {
  type        = bool
  description = "Whether to terminate connections at the end of the deregistration timeout on Network Load Balancers."
  default     = false
}

variable "lb_deregistration_delay" {
  type        = number
  description = "The time to wait for in-flight requests to complete while deregistering a target."
  default     = 300
}

variable "lb_unhealthy_connection_termination" {
  type        = bool
  description = "Whether the load balancer terminates connections to unhealthy targets."
  default     = true
}

variable "lb_health_check_healthy_threshold" {
  type        = number
  description = "The number of checks before the instance is declared healthy."
  default     = 6
}

variable "lb_health_check_unhealthy_threshold" {
  type        = number
  description = "The number of checks before the instance is declared unhealthy."
  default     = 2
}

variable "lb_health_check_timeout" {
  type        = number
  description = "The interval between checks."
  default     = 5
}

variable "lb_health_check_interval" {
  type        = number
  description = "The length of time before the check times out."
  default     = 10
}

variable "lb_security_group_name" {
  type        = string
  description = "Override the ELB security group name."
  default     = ""
}

variable "lb_ingress_cidr_blocks_rtmp" {
  type        = list(string)
  description = "CIDRs to allow for the RTMP ingress."
  default     = ["0.0.0.0/0"]
}

variable "lb_ingress_cidr_blocks_rtmps" {
  type        = list(string)
  description = "CIDRs to allow for the RTMPS ingress."
  default     = ["0.0.0.0/0"]
}

variable "lb_ssl_policy" {
  type        = string
  description = "Name of the SSL Policy for the listener."
  default     = "ELBSecurityPolicy-TLS13-1-0-2021-06" # Allow TLS 1.3, compatible down to 1.0
}

variable "rtmp_backend_ingress_port" {
  type        = string
  description = "The RTMP backend ingress port (envoy port for rtmp)."
}

variable "rtmp_backend_security_group_id" {
  type        = string
  description = "The RTMP backend security group id (used to allow ingress on rtmp_backend_ingress_port)."
}

variable "rtmp_backend_autoscaling_group_name" {
  type        = string
  description = "The RTMP backend ASG name."
  default     = ""
}

variable "access_logs_enabled" {
  type        = bool
  description = "Wether to enable elb access logs or not."
  default     = false
}

variable "access_logs_bucket_name" {
  type        = string
  description = "Override the access logs bucket name."
  default     = ""
}

variable "access_logs_bucket_prefix" {
  type        = string
  description = "The access logs bucket prefix. Logs are stored in the root if not configured."
  default     = null
}

variable "access_logs_expiration" {
  type        = number
  description = "Specifies the number of days for which access logs are kept (indefinitely if not specified)."
  default     = null
}

variable "access_logs_force_destroy" {
  type        = bool
  description = "A boolean that indicates all objects should be deleted from the access logs bucket so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}

variable "rtmps_enabled" {
  type        = bool
  description = "Wether to enable rtmps. If set to true, a certificate will be created in certificate manager as well as load balancer configuration to perform ssl termination."
  default     = true
}

variable "create_cert" {
  type        = bool
  description = "Should the certificate be created by the module. If not, you must provide var.ssl_certificate_arn."
  default     = true
}

variable "dns_hosted_zone_id" {
  type        = string
  description = "The ID of the hosted zone in Route53, under which the DNS record should be created."
}

variable "dns_record" {
  type        = string
  description = "The domain name record to add in zone defined by dns_hosted_zone_id for alias on elb dns name."
  default     = "rtmp"
}

variable "ssl_certificate_arn" {
  type        = string
  description = "The ARN identifier of an existing Certificate in AWS Certificate Manager, to be used for RTMPS requests. If not defined, a new certificate will be issued and validated in the AWS Certificate Manager."
  default     = null
}

variable "ssl_certificate_name" {
  type        = string
  description = "Override the cert manager certificate name."
  default     = ""
}

variable "ssl_certificate_domain_name" {
  type        = string
  description = "The complete domain name that will be written in the TLS certificate. Can include a wildcard. Required for RTMPS."
  default     = null
}

variable "tags" {
  type        = map(any)
  description = "Tags to apply to resources. A list of key->value pairs."
  default     = {}
}

variable "enable_bucket_encryption" {
  type        = bool
  description = "Should the created bucket be encrypted using SSE-S3."
  default     = true
}
