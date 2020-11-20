#
## main.tf Runner file
#
variable "efs_mount_name"{
}

variable "security_group_id"{
}

variable "subnet_id_priv"{
}

#
## Build Resources
#
resource "aws_efs_file_system" "create_efs_mount" {
  tags = {
    Name = var.efs_mount_name
    encrypted = true
  }
}

resource "aws_efs_mount_target" "create_efs_mount_target" {
  file_system_id = aws_efs_file_system.create_efs_mount.id
  subnet_id      = var.subnet_id_priv
  security_groups = [var.security_group_id]
}

#
## Output Varaibles to be Called
#
output "efs_mount_dns" {
  value = aws_efs_file_system.create_efs_mount.dns_name
}

output "efs_mount_id" {
  value = aws_efs_file_system.create_efs_mount.id
}

