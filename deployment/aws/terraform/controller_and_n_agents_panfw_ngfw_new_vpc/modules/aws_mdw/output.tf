output "mdw_detail" {
  value = {
    "name": aws_instance.aws_mdw.tags.Name,
    "private_ip" : aws_instance.aws_mdw.private_ip
    "public_ip"  : aws_eip.mdw_public_ip.public_ip
  }
}

output "name" {
  value = aws_instance.aws_mdw.tags.Name
}

output "private_ip" {
  value =  aws_instance.aws_mdw.private_ip
}

output "public_ip" {
  value =  aws_eip.mdw_public_ip.public_ip
}
