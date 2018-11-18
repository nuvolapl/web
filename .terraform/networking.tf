resource "aws_service_discovery_service" "web" {
    name = "web"

    dns_config {
        namespace_id = "${var.service-discovery-private-dns-namespace-id}"

        dns_records {
            type = "SRV"
            ttl  = 0
        }
    }

    health_check_custom_config {
        failure_threshold = 1
    }
}

resource "aws_security_group" "web" {
    name_prefix = "nuvola-web-"
    vpc_id      = "${var.vpc-id}"

    ingress {
        from_port       = 9000
        to_port         = 9000
        protocol        = "TCP"
        security_groups = ["${var.security-group-proxy-id}"]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"]
    }
}
