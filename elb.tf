resource "aws_alb" "main" {
  name            = "cloud-engineer-alb"
  subnets         = module.vpc.public_subnets
  security_groups = [aws_security_group.main.id]
}

resource "aws_alb_target_group" "main" {
  name        = "cloud-engineer-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
}

resource "aws_alb_listener" "main" {
  load_balancer_arn = aws_alb.main.arn
  port = 80
  protocol = "HTTP"

  default_action {
    target_group_arn = aws_alb_target_group.main.arn
    type = "forward"
  }
}