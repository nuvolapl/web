resource "aws_appautoscaling_target" "service-web" {
    service_namespace  = "ecs"

    resource_id        = "service/${var.ecs-cluster-name}/${aws_ecs_service.web.name}"

    scalable_dimension = "ecs:service:DesiredCount"

    min_capacity       = "${aws_ecs_service.web.desired_count}"
    max_capacity       = "${aws_ecs_service.web.desired_count + ceil(aws_ecs_service.web.desired_count * 0.5)}"
}

resource "aws_appautoscaling_policy" "service-web-up" {
    name               = "nuvola-service-web-up"
    service_namespace  = "${aws_appautoscaling_target.service-web.service_namespace}"
    resource_id        = "service/${var.ecs-cluster-name}/${aws_ecs_service.web.name}"

    scalable_dimension = "${aws_appautoscaling_target.service-web.scalable_dimension}"

    depends_on         = ["aws_appautoscaling_target.service-web"]

    step_scaling_policy_configuration {
        adjustment_type         = "ChangeInCapacity"
        cooldown                = 60
        metric_aggregation_type = "Maximum"

        step_adjustment {
            metric_interval_lower_bound = 0
            scaling_adjustment          = 1
        }
    }
}

resource "aws_appautoscaling_policy" "service-web-down" {
    name               = "nuvola-service-web-down"
    service_namespace  = "${aws_appautoscaling_target.service-web.service_namespace}"
    resource_id        = "service/${var.ecs-cluster-name}/${aws_ecs_service.web.name}"

    scalable_dimension = "${aws_appautoscaling_target.service-web.scalable_dimension}"

    depends_on         = ["aws_appautoscaling_target.service-web"]

    step_scaling_policy_configuration {
        adjustment_type         = "ChangeInCapacity"
        cooldown                = 60
        metric_aggregation_type = "Maximum"

        step_adjustment {
            metric_interval_lower_bound = 0
            scaling_adjustment          = -1
        }
    }

}

resource "aws_cloudwatch_metric_alarm" "service-cpu-high" {
    alarm_name          = "nuvola-service-cpu-high"
    namespace           = "AWS/ECS"

    comparison_operator = "GreaterThanOrEqualToThreshold"
    evaluation_periods  = 2

    metric_name         = "CPUUtilization"
    statistic           = "Maximum"
    period              = 120
    threshold           = 90

    alarm_actions       = ["${aws_appautoscaling_policy.service-web-up.arn}"]
    ok_actions          = ["${aws_appautoscaling_policy.service-web-down.arn}"]

    dimensions {
        ClusterName = "${var.ecs-cluster-name}"
        ServiceName = "${aws_ecs_service.web.name}"
    }
}
