provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-ecs-cluster"
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-ecs-task"
  network_mode            = "awsvpc"

  container_definitions = jsonencode([{
    name  = "my-container"
    image = "nginx:latest"
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])
}

resource "aws_lb" "my_lb" {
  name               = "my-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups   = [aws_security_group.my_sg.id]
  subnets            = ["subnet-12345678", "subnet-23456789"]  # Change these to your subnet IDs
}

resource "aws_security_group" "my_sg" {
  name_prefix = "my-sg-"
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-12345678"  # Change this to your VPC ID
}

resource "aws_lb_listener" "my_listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  default_action {
    type             = "fixed-response"
    status_code      = "200"
    content_type     = "text/plain"
    content          = "Hello, world!"
  }
}

resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "EC2"
  desired_count   = 2

  network_configuration {
    subnets = ["subnet-12345678", "subnet-23456789"]  # Change these to your subnet IDs
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }
}