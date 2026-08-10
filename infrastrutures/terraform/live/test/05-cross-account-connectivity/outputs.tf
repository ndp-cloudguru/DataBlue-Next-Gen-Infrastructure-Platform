output "vpc_peering_connection_id" { value = aws_vpc_peering_connection.this.id }
output "entry_nlb_dns_name" { value = data.terraform_remote_state.entry.outputs.nlb_dns_name }
