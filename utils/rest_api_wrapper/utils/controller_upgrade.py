import sys, time
sys.path.append("..")
from RESTasV3 import RESTasV3
# Support  for updating the Controller using a .tar file that is situated on the same machine where this script is executed

controller_ip = "A.B.C.D"
upgrade_file_path = "path/to/upgrade/file"
importTimeout=1800
installTimeout=5400

rest = RESTasV3(controller_ip)
rest.connect_to_mdw()

# package upload
print(f"Upload the file from: '{upgrade_file_path}' to controller at IP address: {controller_ip}.")
response = rest.upload_package(upgrade_file_path)
apiPathJobStatus = response["url"]

print("The uploaded file will now be imported")
timeout = time.time() + importTimeout
while time.time() < timeout:
    try:
        time.sleep(30)
        response = rest._RESTasV3__sendGet(apiPathJobStatus, 200).json()
        if response["state"] == "SUCCESS":
            print("Package import was successful.")
            upload_finished = True
            rest.session.close()
            break
        elif response["state"] == "ERROR":
            rest.session.close()
            raise "Package import was not successful."
    except Exception:
        continue

if upload_finished == False:
    raise "New version was not uploaded in time."

# check controller is ready for installing
install_finished = False

time.sleep(30) # give some time for staging area to be available
apiPath = '/api/v2/deployment/helm/cluster/staging/operations/deploy/status'
response = rest._RESTasV3__sendGet(apiPath, 200).json()
if response["message"] == "Empty staging area":
    raise "Staging area is empty. There is no package to be installed."

# install package
response = rest.deploy()

timeout = time.time() + installTimeout
install_finished = False
while time.time() < timeout:
    try:
        time.sleep(10)
        response = rest._RESTasV3__sendGet(apiPath, 200).json()
        if response["state"] == "SUCCESS":
            print("Package install was successful.")
            install_finished = True
            rest.session.close()
            break
        elif response["state"] == "ERROR":
            rest.session.close()
            break
    except Exception:
        continue

if install_finished is False:
    raise "New version was not installed."
print("Upgrade completed")



