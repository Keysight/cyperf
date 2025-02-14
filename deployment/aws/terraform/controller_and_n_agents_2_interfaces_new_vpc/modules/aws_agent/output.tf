output "agents_detail"{
  value = {
      "instanceId" : aws_instance.aws_agent.id
      "name": aws_instance.aws_agent.tags.Name,
      "private_ip": aws_instance.aws_agent.private_ip,
    }
}

output "name" {
    value = aws_instance.aws_agent.tags.Name
}
output "private_ip" {
    value = aws_instance.aws_agent.private_ip
}
