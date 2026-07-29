output "bastion_public_ip" {
  value = aws_instance.public_server.public_ip
}

output "private_server_ip" {
  value = aws_instance.private_server.private_ip
}