output "vpc_id" {
  value = aws_vpc.custom.id
}

output "private_subnets" {
  value = aws_subnet.private.*.id
}

output "public_subnets" {
  value = aws_subnet.public.*.id
}

output "private_routes_tables" {
  value = aws_route_table.private_routes.*.id
}
