//outputs
output "ssh_private_key_path" {
    value = local_file.private_key.filename
}   
 

output "ssh_to_bastion_command" {
  value = {
    for k, eip in aws_eip.bastion_eip :
    k => "ssh -i ${path.module}/my-key.pem ec2-user@${eip.public_ip}"
  }
}

output "ssh_to_web_server_via_bastion" {
  value = {
    for k, server in aws_instance.web_server :
    k => "ssh -i ${path.module}/my-key.pem -J ec2-user@${aws_eip.bastion_eip[k].public_ip} ec2-user@${server.private_ip}"
  }
}