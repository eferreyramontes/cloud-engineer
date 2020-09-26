resource "aws_lb" "main" {
  name               = "cloud-engineer-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.main.id]
  subnets            = module.vpc.public_subnets

  enable_deletion_protection = false

  tags = var.tags
}

resource "aws_lb_target_group" "main" {
  name        = "cloud-engineer-alb-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"

  tags = var.tags
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    target_group_arn = aws_lb_target_group.main.arn
    type             = "forward"
  }
}

//resource "aws_lb_listener" "https" {
//  load_balancer_arn = aws_lb.main.arn
//  port              = "443"
//  protocol          = "HTTPS"
//  ssl_policy        = "ELBSecurityPolicy-2016-08"
//  certificate_arn   = "arn:aws:iam::187416307283:server-certificate/test_cert_rab3wuqwgja25ct3n4jdj2tzu4"
//
//  default_action {
//    type             = "forward"
//    target_group_arn = aws_lb_target_group.main.arn
//  }
//}