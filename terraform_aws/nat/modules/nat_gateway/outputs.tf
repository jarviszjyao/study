output "nat_gateway_ids" {
  description = "List of NAT Gateway IDs"
  value       = aws_nat_gateway.this.*.id
}

output "nat_gateway_public_ips" {
  description = "List of public Elastic IPs created for AWS NAT Gateway"
  value       = aws_eip.nat.*.public_ip
}

output "private_route_table_ids" {
  description = "List of IDs of private route tables (created or existing)"
  value       = local.private_route_table_ids
}

output "private_route_table_created_ids" {
  description = "List of IDs of private route tables created by this module"
  value       = aws_route_table.private.*.id
}

output "nat_gateway_route_ids" {
  description = "List of NAT Gateway route IDs for the main CIDR block"
  value       = aws_route.private_nat_gateway.*.id
}

output "additional_route_ids" {
  description = "Map of additional route IDs created for additional CIDR blocks"
  value       = { for k, v in aws_route.additional_cidr_routes : k => v.id }
}

output "private_route_table_association_ids" {
  description = "List of IDs of the private route table association"
  value       = aws_route_table_association.private.*.id
}

output "route_table_count" {
  description = "Number of route tables created or managed"
  value       = length(local.private_route_table_ids)
}

output "nat_gateway_count" {
  description = "Number of NAT Gateways created"
  value       = local.nat_gateway_count
}
