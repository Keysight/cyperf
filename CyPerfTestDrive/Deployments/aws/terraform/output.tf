output "aws_lb-ApplicationElasticLB" {
	value = {
		"dns_name" : aws_lb.ApplicationElasticLB.dns_name
	}
}

output "aws_instance-CyPerfUI" {
	value = {
		"public_dns" : aws_instance.CyPerfUI.public_dns
		"public_ip" : aws_instance.CyPerfUI.public_ip
	}
}