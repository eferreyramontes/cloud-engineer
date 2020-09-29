resource "aws_ecs_cluster" "cluster" {
  name = "cloud-engineer-cluster"

  tags = var.tags
}

resource "aws_ecs_service" "main" {
  name            = "cloud-engineer-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 2
  launch_type     = "FARGATE"

  network_configuration {
    security_groups = [
    aws_security_group.main.id]
    subnets = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.main.arn
    container_name   = "cloud-engineer-app"
    container_port   = 80
  }

  depends_on = [
    aws_lb_listener.main
  ]
}

resource "aws_ecs_task_definition" "service" {
  family       = "service"
  network_mode = "awsvpc"
  requires_compatibilities = [
  "FARGATE"]
  cpu                = 256
  memory             = 512
  execution_role_arn = aws_iam_role.main.arn

  tags = var.tags

  container_definitions = jsonencode([
    {
      name : "cloud-engineer-app",
      image : "tutum/hello-world",
      cpu : 256,
      memory : 512,
      essential : true,
      readonly_root_filesystem = false,
      portMappings : [
        {
          containerPort : 80,
          hostPort : 80
        }
      ]
  }])
}

resource "aws_appautoscaling_target" "ecs_target" {
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.cluster.name}/${aws_ecs_service.main.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "ecs_scale_in_policy" {
  name               = "scale-in"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Average"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = -1
    }
  }
}

resource "aws_appautoscaling_policy" "ecs_scale_out_policy" {
  name               = "scale-out"
  policy_type        = "StepScaling"
  resource_id        = aws_appautoscaling_target.ecs_target.resource_id
  scalable_dimension = aws_appautoscaling_target.ecs_target.scalable_dimension
  service_namespace  = aws_appautoscaling_target.ecs_target.service_namespace

  step_scaling_policy_configuration {
    adjustment_type         = "ChangeInCapacity"
    cooldown                = 60
    metric_aggregation_type = "Maximum"

    step_adjustment {
      metric_interval_upper_bound = 0
      scaling_adjustment          = 1
    }
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_high" {
  alarm_name          = "cloud-engineer-scale-out-metric"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "80"

  alarm_description = "Metric alarm to report high cpu usage"
  alarm_actions     = ["${aws_appautoscaling_policy.ecs_scale_out_policy.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "cpu_utilization_low" {
  alarm_name          = "cloud-engineer-scale-in-metric"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/ECS"
  period              = "120"
  statistic           = "Maximum"
  threshold           = "20"

  alarm_description = "Metric alarm to report low cpu usage"
  alarm_actions     = ["${aws_appautoscaling_policy.ecs_scale_in_policy.arn}"]
}