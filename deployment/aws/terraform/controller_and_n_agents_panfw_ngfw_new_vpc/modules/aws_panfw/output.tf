output "panfw_detail" {
  value = {
    "name": aws_instance.aws_panfw.tags.Name,
    "private_ip" : aws_instance.aws_panfw.private_ip,
    "public_ip"  : aws_eip.panfw_public_ip.public_ip
  }
}

output "name" {
  value = aws_instance.aws_panfw.tags.Name
}

output "private_ip" {
  value =  aws_instance.aws_panfw.private_ip
}

output "public_ip" {
  value =  aws_eip.panfw_public_ip.public_ip
}
