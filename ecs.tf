resource "aws_ecs_cluster" "cluster" {
  name = "cloud-engineer-cluster"
}

resource "aws_ecs_service" "main" {
  name            = "cloud-engineer-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.service.arn
  desired_count   = 4
  launch_type     = "FARGATE"
  #iam_role        = aws_iam_role.main.arn

  network_configuration {
    security_groups = [aws_security_group.main.id]
    subnets         = module.vpc.private_subnets
  }

  load_balancer {
    target_group_arn = aws_alb_target_group.main.arn
    container_name   = "cloud-engineer-app"
    container_port   = 80
  }

  depends_on = [
    aws_alb_listener.main
  ]
}

resource "aws_ecs_task_definition" "service" {
  family                   = "service"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.main.arn

  container_definitions = jsonencode([{
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