variable "aws_profile" {
  type        = string
  description = "AWS CLI profile"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for resources"
}

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

resource "aws_ecs_cluster" "create_ecs_cluster" {
  name = "${terraform.workspace}-ecs"

  tags = {
    Name: "${terraform.workspace}-ecs"
  }
}

resource "aws_cloudwatch_log_group" "create_cw_log_group" {
  name = "${terraform.workspace}-wp"
}

resource "aws_ecs_task_definition" "wp" {
  family                = "${terraform.workspace}-wp"
  container_definitions =  <<-TASK_DEF
  [
    {
      "name": "${terraform.workspace}-wp",
      "image": "wordpress:5.5.3",
      "logConfiguration": {
          "logDriver": "awslogs",
          "options": {
              "awslogs-group": "${aws_cloudwatch_log_group.create_cw_log_group.name}",
              "awslogs-region": "${var.aws_region}",
              "awslogs-stream-prefix": "wp"
          }
      },
      "memory": 512,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 8000,
          "protocol": "tcp"
        }
      ],
      "essential": true,
      "mountPoints": [
        {
          "sourceVolume": "webData",
          "containerPath": "/var/www/html",
          "readOnly": false
        }
      ],
      "privileged": false,
      "readonlyRootFilesystem": false
    }
  ]
  TASK_DEF
  
  volume {
    name      = "webData"
    host_path = "/webData/"
  }

}

resource "aws_ecs_service" "create_service" {
  name            = "${terraform.workspace}-wp"
  cluster         = aws_ecs_cluster.create_ecs_cluster.arn
  task_definition = aws_ecs_task_definition.wp.arn
  desired_count   = 1
}
