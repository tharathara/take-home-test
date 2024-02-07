terraform {
  required_version = ">= 0.12"

  backend "s3" {
    bucket         = "take-home-bucket"
    key            = "remote/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
  }
}

provider "aws" {
  region = "us-east-1"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "ec2_private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "ec2_private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"
}

resource "aws_subnet" "elb_public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.20.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "elb_public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.21.0/24"
  availability_zone = "us-east-1b"
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "internet_gateway_route" {
  route_table_id         = aws_route_table.elb_public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

# Route Table
resource "aws_route_table" "ec2_private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "elb_public_rt" {
  vpc_id = aws_vpc.main.id
}

# NACL
resource "aws_network_acl" "ec2_private_nacl" {
  vpc_id = aws_vpc.main.id
}

resource "aws_network_acl" "elb_public_nacl" {
  vpc_id = aws_vpc.main.id
}

# ALB
resource "aws_lb" "main" {
  name               = "take-home-app-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.elb_public_1.id, aws_subnet.elb_public_2.id]

  tags = {
    Name = "take-home-app-alb"
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "redirect"
    redirect {
      port         = "443"
      protocol     = "HTTPS"
      status_code  = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "main" {
  name     = "take-home-app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    port                = 80   # Change to the port your application listens on
    protocol            = "HTTP"
    timeout             = 5
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

# ECS
resource "aws_ecs_cluster" "main" {
  name = "take-home-app-cluster"
}

# IAM
resource "aws_iam_role" "ecs_task_execution" {
  name               = "take-home-app-ecs-task-execution-role"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "ecs-tasks.amazonaws.com"
        },
        "Action" : "sts:AssumeRole"
      }
    ]
  })
}

# IAM policy for ECS service execution
resource "aws_iam_policy" "ecs_service_execution_policy" {
  name        = "ecs-service-execution-policy"
  description = "IAM policy for ECS service execution"
  policy      = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": [
          "ecs:CreateCluster",
          "ecs:DeregisterContainerInstance",
          "ecs:DiscoverPollEndpoint",
          "ecs:Poll",
          "ecs:RegisterContainerInstance",
          "ecs:StartTelemetrySession",
          "ecs:Submit*",
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetRepositoryPolicy",
          "ecr:DescribeRepositories",
          "ecr:ListImages",
          "ecr:BatchGetImage",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams",
          "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
          "elasticloadbalancing:DeregisterTargets",
          "elasticloadbalancing:Describe*",
          "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
          "elasticloadbalancing:RegisterTargets"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_policy_attachment" "ecs_service_execution" {
  name       = "ecs-service-execution-attachment"
  roles      = [aws_iam_role.ecs_task_execution.name]
  policy_arn = aws_iam_policy.ecs_service_execution_policy.arn
}

output "ecs_cluster_id" {
  value = aws_ecs_cluster.main.id
}
