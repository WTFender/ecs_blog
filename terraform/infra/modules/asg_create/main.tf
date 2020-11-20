#
## main.tf Runner file
#
variable "launch_config_name" {
}

variable "ami_id" {
}

variable "iam_instance_profile" {
}

variable "key_name" {
}

variable "security_groups" {
}


variable "vpc_id" {
}

variable "subnet_id_priv" {
}

variable "target_group_arns" {
}

variable "user_data" {
}

variable "instance_type" {
}

variable "min_size" {
}

variable "max_size" {
}

variable "desired_capacity" {
}

variable "service_linked_role_arn" {
}


#
## Build Resources
#



resource "aws_launch_configuration" "create_launch_config" {
  name_prefix   = var.launch_config_name
  image_id      = var.ami_id
  instance_type = var.instance_type
  iam_instance_profile = var.iam_instance_profile
  key_name = var.key_name
  security_groups = var.security_groups
  user_data = var.user_data
  associate_public_ip_address = false

  root_block_device{
    volume_type = "gp2"
    volume_size = 40
  
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "create_asg" {
  name                 = "${aws_launch_configuration.create_launch_config.name}-${var.launch_config_name}"
  launch_configuration = aws_launch_configuration.create_launch_config.name
  min_size             = var.min_size
  max_size             = var.max_size
  desired_capacity     = var.desired_capacity
  vpc_zone_identifier  = [var.subnet_id_priv]
  target_group_arns = var.target_group_arns
  service_linked_role_arn = var.service_linked_role_arn
  
  
  lifecycle {
    create_before_destroy = true
  }

  tag {
      key                 = "Name"
      value               = var.launch_config_name
      propagate_at_launch = true
    }
}

#
## Output Varaibles to be Called
#
output "asg_output_arn" {
  value = aws_autoscaling_group.create_asg.arn
}