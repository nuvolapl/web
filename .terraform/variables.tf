variable "region" {
    description = ""
}

variable "cloudwatch-log-group-name" {
    description = ""
}

variable "vpc-id" {
    description = ""
}

variable "vpc-private-subnets" {
    type        = "list"
    description = ""
}

variable "security-group-proxy-id" {
    description = ""
}

variable "service-discovery-private-dns-namespace-id" {
    description = ""
}

variable "ecs-cluster-id" {
    description = ""
}

variable "iam-role-ecs-td-arn" {
    description = ""
}

variable "s3-bucket-arn" {
    description = ""
}

variable "s3-bucket-name" {
    description = ""
}

variable "s3-bucket-prefix" {
    description = ""
}

variable "ecs-cluster-name" {
    description = ""
}
