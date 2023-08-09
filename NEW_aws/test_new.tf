provider "aws" {
  region = "us-east-1"  # Change this to your desired region
}

resource "aws_ecs_task_definition" "my_task" {
  family                  = "my-ecs-task"
  network_mode            = "bridge"

  container_definitions = jsonencode([{
    name  = "dummy_container_MP"
    image = "nginx:latest"
    memory = 256
    requires_compatibilities = ["EC2"]
    portMappings = [{
      containerPort = 80
      hostPort      = 80
    }]
  }])

}
resource "aws_lb" "my_lb" {
  name               = "xpay-checkout-back-prd-LB-MP"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [var.existing_security_group_id]
  subnets            = ["subnet-0ff2486e3ed4470c7", "subnet-0c6182e1babe3e8c4"]  # Change these to your subnet IDs
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "xpay-checkout-back-prd-TG-MP"
  target_type = "instance"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "vpc-06713303efcb55aac"  # Change this to your VPC ID
}

resource "aws_alb_listener" "alb-http-listener" {
  load_balancer_arn = aws_lb.my_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.id
  }
}
# Existing security group ID to be used for ECS tasks
variable "existing_security_group_id" {
  description = "ID of the existing security group"
  default     = "sg-07e9824cfe6a5dc39"  # Replace with the actual security group ID
}

resource "aws_ecs_service" "my_service" {
  name            = "my-ecs-service"
  cluster         = "xpay-checkout-prd"  # Change this to your ECS cluster name
  task_definition = aws_ecs_task_definition.my_task.arn
  launch_type     = "EC2"
  desired_count   = 1

#  network_configuration {
#    subnets = ["subnet-0b8e8e15c2d48f4af", "subnet-03e033705a9fdf1ab"]  # Change these to your subnet IDs
#    security_groups = [var.existing_security_group_id]  # Use the existing security group ID
#  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "dummy_container_MP"
    container_port   = 80
  }
}
