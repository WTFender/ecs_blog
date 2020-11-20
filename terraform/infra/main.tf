variable "aws_profile" {
  type        = string
  description = "AWS CLI profile"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for resources"
}

variable "rds_security_group" {
  type        = string
  description = "RDS Security Group ID"
}

variable "service_role" {
  type        = string
  description = "ECS host service role"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "subnet_id_priv" {
  type        = string
  description = "Subnet ID"
}

variable "subnet_id_priv2" {
  type        = string
  description = "Subnet ID"
}

variable "subnet_id_for_alb" {
  type        = string
  description = "Subnet ID"
}

variable "keypair_name" {
  type        = string
  description = "EC2 KeyPair to use"
}


variable "acm_arn" {
  type        = string
  description = "ACM Cert ARN"
}
/*
variable "hosted_zone_id" {
  type = string
  description = "Hosted Zone ID for cybersecurity dtci tech"
  default = "Z2R6K7690UBLWM"
}

variable "kms_key_id_west" {
  type=string
  description = "KMS Key ID us-west-1"
  default = "arn:aws:kms:us-west-1:271278606726:key/3c3062b0-f025-46cf-81fb-c2b3a1297367"
}

data "terraform_remote_state" "docker_image" {
    backend = "s3" 
    config = {
        bucket = "cf-dtci-seceng-terraform-state-bucket"
        key    = "env:/aws_threadfix-prod/terraform-states/state.tfstate"
        region = "us-west-1"  
    }
}
*/

#################

provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

### Security Groups

resource "aws_security_group" "create_alb_sg" {
  name        = "${terraform.workspace}-sg-alb"
  description = "Allow web traffic to ALB"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "create_ec2_sg" {
  name        = "${terraform.workspace}-sg-ec2"
  description = "Allow ALB and bastion to ECS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.create_alb_sg.id]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["98.148.226.110/32"]
  }
}

resource "aws_security_group" "create_efs_sg" {
  name        = "${terraform.workspace}-sg-efs"
  description = "Allow ALB and bastion to EFS"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.create_ec2_sg.id]
  }
}

resource "aws_security_group_rule" "create_rds_sg_rule" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = var.rds_security_group
  source_security_group_id = aws_security_group.create_ec2_sg.id
}

### IAM

resource "aws_iam_role" "create_ecs_ec2_role" {
  name = "${terraform.workspace}-ecs-instance-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_policy" "create_ecs_iam_policy" {
  name        = "${terraform.workspace}-ecs-iam-pol"
  description = "Policy to allow ECS functions via Instance roles"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor3",
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents",
                "logs:DescribeLogStreams"
            ],
            "Resource": [
                "arn:aws:logs:*:*:*"
            ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssm:DescribeAssociation",
                "ssm:GetDeployablePatchSnapshotForInstance",
                "ssm:GetDocument",
                "ssm:DescribeDocument",
                "ssm:GetManifest",
                "ssm:GetParameter",
                "ssm:GetParameters",
                "ssm:ListAssociations",
                "ssm:ListInstanceAssociations",
                "ssm:PutInventory",
                "ssm:PutComplianceItems",
                "ssm:PutConfigurePackageResult",
                "ssm:UpdateAssociationStatus",
                "ssm:UpdateInstanceAssociationStatus",
                "ssm:UpdateInstanceInformation"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ssmmessages:CreateControlChannel",
                "ssmmessages:CreateDataChannel",
                "ssmmessages:OpenControlChannel",
                "ssmmessages:OpenDataChannel"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2messages:AcknowledgeMessage",
                "ec2messages:DeleteMessage",
                "ec2messages:FailMessage",
                "ec2messages:GetEndpoint",
                "ec2messages:GetMessages",
                "ec2messages:SendReply"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeTags",
                "ecs:CreateCluster",
                "ecs:DeregisterContainerInstance",
                "ecs:DiscoverPollEndpoint",
                "ecs:Poll",
                "ecs:RegisterContainerInstance",
                "ecs:StartTelemetrySession",
                "ecs:UpdateContainerInstancesState",
                "ecs:Submit*",
                "ecr:GetAuthorizationToken",
                "ecr:BatchCheckLayerAvailability",
                "ecr:GetDownloadUrlForLayer",
                "ecr:BatchGetImage",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "attach_ecs_iam_pol" {
  role       = aws_iam_role.create_ecs_ec2_role.name
  policy_arn = aws_iam_policy.create_ecs_iam_policy.arn
}

resource "aws_iam_instance_profile" "create_ecs_instance_profile" {
  name = "${terraform.workspace}-ecs_instance_profile"
  role = aws_iam_role.create_ecs_ec2_role.name
}

### ALB

resource "aws_lb" "create_alb" {
  name               = "${terraform.workspace}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [var.subnet_id_priv, var.subnet_id_priv2]
  security_groups    = [aws_security_group.create_alb_sg.id]
}

resource "aws_lb_listener" "create_listener_redirect" {
  load_balancer_arn = aws_lb.create_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_target_group" "create_tg" {
  name     = "${terraform.workspace}-wp"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path     = "/"
    port     = 8000
    healthy_threshold = 6
    unhealthy_threshold = 2
    protocol = "HTTP"
    matcher = "200-399"
  }
}

resource "aws_lb_listener" "create_listener_https" {
  load_balancer_arn = aws_lb.create_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = var.acm_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.create_tg.arn
  }
}



### EFS

module "create_efs" {
  source            = "./modules/efs_create"
  efs_mount_name    = "${terraform.workspace}-efs"
  security_group_id = aws_security_group.create_efs_sg.id
  subnet_id_priv    = var.subnet_id_priv
  providers = {
    aws = aws
  }
}

### ECS EC2 HOST

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
}

module "create_asg" {
  source                  = "./modules/asg_create"
  launch_config_name      = "${terraform.workspace}-ecs-host"
  ami_id                  = data.aws_ami.ecs_ami.image_id
  iam_instance_profile    = aws_iam_instance_profile.create_ecs_instance_profile.name
  service_linked_role_arn = var.service_role
  key_name                = var.keypair_name
  user_data               = <<-EOT
    #cloud-boothook
    #!/bin/sh
    cat <<'EOF' >> /etc/ecs/ecs.config
    ECS_CLUSTER=${terraform.workspace}-ecs
    ECS_CONTAINER_INSTANCE_PROPAGATE_TAGS_FROM=ec2_instance
    ECS_INSTANCE_ATTRIBUTES={"purpose": "ecs-host"}
    EOF
    # mount efs
    yum install -y nfs-utils aws-cli
    mkdir /webData
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${module.create_efs.efs_mount_dns}:/ /webData
    crontab<<EOF
    sudo mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,noresvport ${module.create_efs.efs_mount_dns}:/ /webData
    EOF
  EOT

  security_groups   = [aws_security_group.create_alb_sg.id, aws_security_group.create_ec2_sg.id, aws_security_group.create_efs_sg.id]
  target_group_arns = [aws_lb_target_group.create_tg.arn]
  subnet_id_priv    = var.subnet_id_priv
  instance_type     = "t2.micro"
  min_size          = 1
  max_size          = 1
  desired_capacity  = 1
  vpc_id            = var.vpc_id
  providers = {
    aws = aws
  }
}
