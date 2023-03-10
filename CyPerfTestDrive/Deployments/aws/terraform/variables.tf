
variable "AgentAmiName" {
	default = "keysight-cyperf-agent-2-1"
	description = "AMI name used for deploying Agent instances"
	type = string
}

variable "AgentAmiOwner" {
	default = "001382923476"
	description = "Owner of AMI used for deploying Agent instances"
	type = string
}

variable "AgentControlCidr" {
	default = "172.16.1.0/24"
	description = "CyPerf agents will use this subnet for control plane communication with controller"
	validation {
		condition = length(var.AgentControlCidr) >= 9 && length(var.AgentControlCidr) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentControlCidr))
		error_message = "AgentControlCidr must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AgentControlCidr1" {
	default = "172.16.5.0/24"
	description = "CyPerf agents at AZ1 will use this subnet for control plane communication with controller"
	validation {
		condition = length(var.AgentControlCidr1) >= 9 && length(var.AgentControlCidr1) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentControlCidr1))
		error_message = "AgentControlCidr1 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AgentControlCidr2" {
	default = "172.16.6.0/24"
	description = "CyPerf agents at AZ2 will use this subnet for control plane communication with controller"
	validation {
		condition = length(var.AgentControlCidr2) >= 9 && length(var.AgentControlCidr2) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentControlCidr2))
		error_message = "AgentControlCidr2 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AgentTestCidr" {
	default = "172.16.2.0/24"
	description = "CyPerf agents will use this subnet for test traffic"
	validation {
		condition = length(var.AgentTestCidr) >= 9 && length(var.AgentTestCidr) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentTestCidr))
		error_message = "AgentTestCidr must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AgentTestCidr1" {
	default = "172.16.3.0/24"
	description = "CyPerf agents will use this subnet for test traffic at AZ1"
	validation {
		condition = length(var.AgentTestCidr1) >= 9 && length(var.AgentTestCidr1) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentTestCidr1))
		error_message = "AgentTestCidr1 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AgentTestCidr2" {
	default = "172.16.4.0/24"
	description = "CyPerf agents will use this subnet for test traffic at AZ2"
	validation {
		condition = length(var.AgentTestCidr2) >= 9 && length(var.AgentTestCidr2) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AgentTestCidr2))
		error_message = "AgentTestCidr2 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "AllowedSubnet" {
	default = "1.1.1.1/1"
	description = "Subnet range allowed to access deployed AWS resources"
	validation {
		condition = length(var.AllowedSubnet) >= 9 && length(var.AllowedSubnet) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.AllowedSubnet))
		error_message = "AllowedSubnet must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "ApplicationLBHTTPHealthChkPort" {
	default = "80"
	description = "TCP/IP port of the ApplicationLB HTTP Health Check"
	type = string
}

variable "ApplicationLBHTTPListenerPort" {
	default = "80"
	description = "TCP/IP port of the ApplicationLB HTTP Listener"
	type = string
}

variable "ApplicationLBHTTPSHealthChkPort" {
	default = "443"
	description = "TCP/IP port of the ApplicationLB HTTPS Health Check"
	type = string
}

variable "ApplicationLBHTTPSListenerPort" {
	default = "443"
	description = "TCP/IP port of the ApplicationLB HTTPS Listener"
	type = string
}

variable "ControllerAmiName" {
	default = "keysight-cyperf-controller-2-1"
	description = "AMI name used for deploying Controller instances"
	type = string
}

variable "ControllerNetworkCidr1" {
	default = "172.16.1.0/24"
	description = "This subnet is attached to CyPerf controller and would be used to access the CyPerf controllers' UI. Also used for Load Balancer subnet for AZ1."
	validation {
		condition = length(var.ControllerNetworkCidr1) >= 9 && length(var.ControllerNetworkCidr1) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.ControllerNetworkCidr1))
		error_message = "ControllerNetworkCidr1 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "ControllerNetworkCidr2" {
	default = "172.16.2.0/24"
	description = "This subnet is used for Load Balancer subnet for AZ2"
	validation {
		condition = length(var.ControllerNetworkCidr2) >= 9 && length(var.ControllerNetworkCidr2) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.ControllerNetworkCidr2))
		error_message = "ControllerNetworkCidr2 must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}

variable "ControllerAmiOwner" {
	default = "001382923476"
	description = "Owner of AMI used for deploying Controller instances"
	type = string
}

variable "CS_Owner_Email" {
	default = "terraform@keysight.com"
	description = "Email address associated with the user owning the resources in this deployment"
	type = string
}

variable "FlowLogTrafficType" {
	default = "REJECT"
	description = "Indicaes the behavior to apply to traffic monitored by the flow log"
	type = string
}

variable "InstanceTypeForCyPerfAgent" {
	validation {
		condition = can(regex("c4.2xlarge", var.InstanceTypeForCyPerfAgent)) || can(regex("c5n.9xlarge", var.InstanceTypeForCyPerfAgent)) || can(regex("c5.large", var.InstanceTypeForCyPerfAgent)) || can(regex("c5.4xlarge", var.InstanceTypeForCyPerfAgent))
		error_message = "InstanceTypeForCyPerfAgent must be one of (t3.xlarge | m5.xlarge) types."
	}
	default = "c5.4xlarge"
	description = "CyPerf instance type"
	type = string
}

variable "InstanceTypeForCyPerfApp" {
	validation {
		condition = can(regex("c4.2xlarge", var.InstanceTypeForCyPerfApp)) || can(regex("c5.2xlarge", var.InstanceTypeForCyPerfApp))
		error_message = "InstanceTypeForCyPerfApp must be one of (c4.2xlarge | c5.2xlarge) types."
	}
	default = "c5.2xlarge"
	description = "CyPerf instance type"
	type = string
}

variable "KeyNameForCyPerfAgent" {
	default = "cs-key"
	description = "Name of an existing EC2 KeyPair to enable SSH access to the CyPerf instances"
	type = string
}

variable "KeyUsername" {
	default = "cyperf"
	description = "Login username associated with EC2 KeyPair to enable SSH access to the CyPerf instances"
	type = string
}

variable "NetworkOutBytesPerMinute" {
	default = "100000"
	description = "Average network out capacity to trigger auto scaling"
	type = string
}

variable "Project" {
	default = "CyPerf-Test-Drive-AWS"
	description = "Project Name"
	type = string
}

variable "RuleAction" {
	default = "BLOCK"
	description = "Indicates the behavior to apply to traffic intercepted by WAF"
	type = string
}

variable "ScaleCapacityMax" {
	default = "1"
	description = "Number of maximum CyPerf Server Agent to run"
	type = string
}

variable "ScaleCapacityMin" {
	default = "1"
	description = "Number of minimum CyPerf Server Agent to run"
	type = string
}

variable "StackName" {
	default = "CyPerf"
	description = "Indicates name of the resource stack to which this deployment belongs"
	type = string
}

variable "StackPrefix" {
	default = "Cyperfwaf"
	description = "Indicates the prefix to which WAF resource stack should begin with"
	type = string
}

variable "TagBehindApplicationLB" {
	default = "ServerFarmBehindALB"
	description = "CyPerf Agent Tag running behind Application LB"
	type = string
}

variable "TimeSleepDelay" {
	default = "2m"
	description = "Indicates the wait delay before continuing with resource creation while other resources initialize fully"
	type = string
}

variable "VpcCidr" {
	default = "172.16.0.0/16"
	description = "Cidr range for the Vpc"
	validation {
		condition = length(var.VpcCidr) >= 9 && length(var.VpcCidr) <= 18 && can(regex("(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})\\.(\\d{1,3})/(\\d{1,2})", var.VpcCidr))
		error_message = "VpcCidr must be a valid IP Cidr range of the form x.x.x.x/x."
	}
	type = string
}