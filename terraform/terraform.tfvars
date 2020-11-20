# AWS
aws_profile   = "test"
aws_region   = "us-west-2"

# VPC
vpc_id = "vpc-1ca41564"
subnet_id_priv = "subnet-7b5f5d02"
subnet_id_priv2 = "subnet-a4089d8f"

# ALB
acm_arn = "arn:aws:acm:us-west-2:391785637824:certificate/291b6c10-cc0c-4f3d-938a-74180e5c7006"
subnet_id_for_alb = "subnet-7b5f5d02"

# EC2
service_role = "arn:aws:iam::391785637824:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
keypair_name = "blog-ec2"

# RDS
rds_security_group = "sg-0ecf9e42"