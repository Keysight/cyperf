import subprocess
import json

def run_terraform():
    # Initialize Terraform
    subprocess.run(["terraform", "init"], check=True)
    
    # Apply Terraform configuration
    subprocess.run(["terraform", "apply", "-auto-approve"], check=True)
    
    # Capture the output in JSON format
    result = subprocess.run(["terraform", "output", "-json"], capture_output=True, text=True, check=True)
    
    # Parse the JSON output
    terraform_output = json.loads(result.stdout)
    
    return terraform_output

# Run the function and store the output
output = run_terraform()

# Access specific details from the output
client_agent_detail = output['client_agent_detail']['value']
mdw_detail = output['mdw_detail']['value']
server_agent_detail = output['server_agent_detail']['value']

print("Client Agent Detail:", client_agent_detail)
print("MDW Detail:", mdw_detail)
print("Server Agent Detail:", server_agent_detail)