import sys, os
sys.path.append("..")
from RESTasV3 import RESTasV3

# CyPerf API sample script to create new CyPerf applications using flows extracted from multiple capture files (pcap and pcapng).
# Name of the capture file will be used as name for new Cyperf app

def find_pcap_files(directory):
    """Search for files with .pcap and .pcapng extensions in the given directory and subdirectories."""
    pcap_files = []
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith(('.pcap', '.pcapng')):
                pcap_files.append(os.path.join(root, file))
    if not pcap_files:
        raise FileNotFoundError("No .pcap or .pcapng files found in the directory.")
    return pcap_files


if __name__ == "__main__":
    capture_folder = "../sample_captures"
    controller = RESTasV3(ipAddress=sys.argv[1])

    try:
        pcap_list = find_pcap_files(capture_folder)
        print("Found the following files:")
        for file in pcap_list:
            print(file)
    except FileNotFoundError as e:
        print(e)
    
    for capture_file in pcap_list:
        capture_name = capture_file.split("/")[-1].split(".")[0]
        app_flow_ids_exchanges = []

        response = controller.upload_capture(capture_file)
        response = controller.wait_event_success(apiPath=response["url"], timeout=300)
        response = controller._RESTasV3__sendGet(response["resultUrl"], 200).json()

        capture_id = response["resourceURL"].split("/")[-1]
        capture_details = [capture_info for capture_info in controller.get_captures()["data"] if capture_info["id"]==capture_id]

        for flow in capture_details[0]["flows"]:
            app_flow_ids_exchanges.append({"app_flow_id": flow["id"], "exchanges_list":[f"{i}" for i in range(len(flow["exchanges"]))]})
        controller.create_app(app_name=capture_name, 
                              action_name=f"{capture_name} single action", 
                              capture_id=capture_id, 
                              app_flow_ids_exchanges=app_flow_ids_exchanges)