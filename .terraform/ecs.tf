resource "aws_ecr_repository" "web" {
    name = "nuvola-web"
}

resource "aws_ecs_task_definition" "web" {
    family                   = "nuvola-web"

    requires_compatibilities = ["FARGATE"]
    network_mode             = "awsvpc"
    cpu                      = "256"
    memory                   = "512"

    execution_role_arn       = "${var.iam-role-ecs-td-arn}"
    task_role_arn            = "${var.iam-role-ecs-td-arn}"

    container_definitions    = <<JSON
[
  {
    "name": "web",
    "image": "${aws_ecr_repository.web.repository_url}",
    "portMappings": [
      {
        "containerPort": 9000,
        "hostPort": 9000
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-region": "${var.region}",
        "awslogs-group": "${var.cloudwatch-log-group-name}",
        "awslogs-stream-prefix": "web"
      }
    }
  }
]
JSON
}

data "aws_ecs_task_definition" "web" {
    task_definition = "${aws_ecs_task_definition.web.family}"
}

resource "aws_ecs_service" "web" {
    name            = "nuvola-web"

    cluster         = "${var.ecs-cluster-id}"
    desired_count   = 1
    launch_type     = "FARGATE"
    task_definition = "${aws_ecs_task_definition.web.family}:${max("${aws_ecs_task_definition.web.revision}", "${data.aws_ecs_task_definition.web.revision}")}"

    network_configuration {
        security_groups  = ["${aws_security_group.web.id}"]
        subnets          = ["${var.vpc-private-subnets}"]
        assign_public_ip = true
    }

    service_registries {
        registry_arn = "${aws_service_discovery_service.web.arn}"
        port         = 9000
    }

    lifecycle {
        ignore_changes = ["desired_count"]
    }
}
