output "id" {
  description = "The ID of the EFS file system"
  value       = aws_efs_file_system.this.id
}

output "arn" {
  description = "The ARN of the EFS file system"
  value       = aws_efs_file_system.this.arn
}

output "dns_name" {
  description = "The DNS name of the EFS file system"
  value       = aws_efs_file_system.this.dns_name
}

output "mount_targets" {
  description = "Map of mount targets created and their attributes"
  value       = aws_efs_mount_target.this
}

output "access_points" {
  description = "Map of access points created and their attributes"
  value       = aws_efs_access_point.this
}

output "mount_target_ips" {
  description = "List of IP addresses of the mount targets"
  value       = local.all_mount_target_ips
}

output "mount_target_dns_names" {
  description = "List of DNS names for the mount targets"
  value = [
    for subnet_id in var.subnet_ids :
    "${aws_efs_file_system.this.id}.${data.aws_region.current.name}.amazonaws.com"
  ]
}

output "vpc_endpoint_id" {
  description = "The ID of the VPC endpoint for EFS (if created)"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.efs[0].id : null
}

output "vpc_endpoint_dns_names" {
  description = "The DNS names of the VPC endpoint for EFS (if created)"
  value       = var.create_vpc_endpoint ? aws_vpc_endpoint.efs[0].dns_entry : null
}

output "mount_targets_count" {
  description = "The number of mount targets created"
  value       = length(aws_efs_mount_target.this)
}

output "access_points_count" {
  description = "The number of access points created"
  value       = length(aws_efs_access_point.this)
}

output "mount_target_network_interface_ids" {
  description = "The network interface IDs of the mount targets"
  value       = [for mt in aws_efs_mount_target.this : mt.network_interface_id]
}

output "file_system_encrypted" {
  description = "Whether the EFS file system is encrypted"
  value       = aws_efs_file_system.this.encrypted
}

output "file_system_kms_key_id" {
  description = "The ARN of the KMS key used for encryption"
  value       = aws_efs_file_system.this.kms_key_id
}

output "file_system_performance_mode" {
  description = "The performance mode of the EFS file system"
  value       = aws_efs_file_system.this.performance_mode
}

output "file_system_throughput_mode" {
  description = "The throughput mode of the EFS file system"
  value       = aws_efs_file_system.this.throughput_mode
}

output "file_system_provisioned_throughput_in_mibps" {
  description = "The provisioned throughput in MiBps (if applicable)"
  value       = aws_efs_file_system.this.provisioned_throughput_in_mibps
}

output "backup_policy_status" {
  description = "The backup policy status of the EFS file system"
  value       = aws_efs_backup_policy.this.backup_policy[0].status
}

output "access_point_dns_names" {
  description = "The DNS names for mounting using the access points"
  value = {
    for k, ap in aws_efs_access_point.this : k => 
    "${aws_efs_file_system.this.id}.efs.${data.aws_region.current.name}.amazonaws.com:/${ap.root_directory[0].path}"
  }
}
