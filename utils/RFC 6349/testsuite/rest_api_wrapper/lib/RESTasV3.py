import os
import io
import sys
import glob
import time
import urllib3
import requests
import simplejson as json
from zipfile import ZipFile
from datetime import datetime

#sys.path.insert(0, os.path.join(os.path.dirname(__file__+"/..")))

#from resources.configuration import WAP_USERNAME, WAP_PASSWORD, WAP_CLIENT_ID


class RESTasV3:

    def __init__(self, ipAddress, username, password, client_id, verify=True):
        
        self.ipAddress = ipAddress
        self.username = username 
        self.password = password
        self.client_id = client_id
        self.verify = verify
        self.session = requests.Session()
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        self.session.verify = False
        self.host = 'https://{}'.format(ipAddress)
        self.cookie = self.get_automation_token()
        self.headers = {'authorization': self.cookie}
        self.startTime = None
        self.startTrafficTime = None
        self.stopTrafficTime = None
        self.stopTime = None
        self.configID = None
        self.sessionID = None
        self.config = None
        self.testDuration = 60
        


    def __sendPost(self, url, payload, customHeaders=None, files=None, debug=True):
        expectedResponse = [200, 201, 202]
        print("POST at URL: {} with payload: {}".format(url, payload))
        payload = json.dumps(payload) if customHeaders is None else payload
        response = self.session.post('{}{}'.format(self.host, url),
                                     headers=customHeaders if customHeaders else self.headers, data=payload,
                                     files=files, verify=False)
        if debug:
            print("POST response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.post('{}{}'.format(self.host, url),
                                         headers=customHeaders if customHeaders else self.headers, data=payload,
                                         files=files, verify=False)
            print("POST response message: {}, response code: {}".format(response.content, response.status_code))
        if self.verify and response.status_code not in expectedResponse:
            raise Exception(
                'Unexpected response code. Actual: {} Expected: {}'.format(response.status_code, expectedResponse))

        return response

    def __sendGet(self, url, expectedResponse, customHeaders=None, debug=True):
        print("GET at URL: {}".format(url))
        response = self.session.get('{}{}'.format(self.host, url),
                                    headers=customHeaders if customHeaders else self.headers)
        if debug:
            print("GET response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.get('{}{}'.format(self.host, url),
                                        headers=customHeaders if customHeaders else self.headers)
            print("GET response message: {}, response code: {}".format(response.content, response.status_code))
        if self.verify and response.status_code != expectedResponse:
            raise Exception(
                'Unexpected response code. Actual: {} Expected: {}'.format(response.status_code, expectedResponse))

        return response

    def __sendPut(self, url, payload, debug=True):
        print("PUT at URL: {} with payload: {}".format(url, payload))
        expectedResponse = [200, 204]
        response = self.session.put('{}{}'.format(self.host, url), headers=self.headers, data=json.dumps(payload))
        if debug:
            print("PUT response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.put('{}{}'.format(self.host, url), headers=self.headers, data=json.dumps(payload))
            print("PUT response message: {}, response code: {}".format(response.content, response.status_code))
        if self.verify and response.status_code not in expectedResponse:
            raise Exception(
                'Unexpected response code. Actual: {} Expected: {}'.format(response.status_code, expectedResponse))

        return response

    def __sendPatch(self, url, payload, debug=True):
        print("PATCH at URL: {} with payload: {}".format(url, payload))
        expectedResponse = [200, 204]
        response = self.session.patch('{}{}'.format(self.host, url), headers=self.headers, data=json.dumps(payload))
        if debug:
            print("PATCH response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.patch('{}{}'.format(self.host, url), headers=self.headers, data=json.dumps(payload))
            print("PATCH response message: {}, response code: {}".format(response.content, response.status_code))
        if self.verify and response.status_code not in expectedResponse:
            raise Exception(
                'Unexpected response code. Actual: {} Expected: {}'.format(response.status_code, expectedResponse))

        return response

    def __sendDelete(self, url, headers=None, debug=True):
        print("DELETE at URL: {}".format(url))
        expectedResponse = [200, 202, 204]
        response = self.session.delete('%s%s' % (self.host, url), headers=headers)
        if debug:
            print("DELETE response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.delete('%s%s' % (self.host, url), headers=headers)
            print("DELETE response message: {}, response code: {}".format(response.content, response.status_code))
        if self.verify and response.status_code not in expectedResponse:
            raise Exception(
                'Unexpected response code. Actual: {} Expected: {}'.format(response.status_code, expectedResponse))

        return response

    def get_automation_token(self):
        apiPath = '/auth/realms/keysight/protocol/openid-connect/token'
        headers = {"content-type": "application/x-www-form-urlencoded"}
        payload = {"username": self.username,
                   "password": self.password,
                   "grant_type": "password",
                   "client_id": self.client_id}

        response = self.__sendPost(apiPath, payload, customHeaders=headers)
        if self.verify:
            if response.headers.get('content-type') == 'application/json':
                response = response.json()
                print('Access Token: {}'.format(response["access_token"]))
                return response['access_token']
            else:
                raise Exception('Fail to obtain authentication token')

        return response

    def refresh_access_token(self):
        access_token = self.get_automation_token()
        self.headers = {'authorization': access_token}
        print('Authentication token refreshed!')

    def setup(self, config=None, config_name=None):
        
        if config:
            self.configID = self.import_config(config)
        else:
            self.configID = config
        self.load_config(test_name = config_name)

        #self.sessionID = self.open_config()
        self.config = self.get_session_config()

    def get_session(self, session_id):
        apiPath = '/api/v2/sessions/{}'.format(session_id)
        response = self.__sendGet(apiPath, 200).json()
        return response

    def delete_session(self, session_id):
        """
        Delete a session by its id
        :param session_id: The id got from getSessions
        """
        apiPath = '/api/v2/sessions/{}'.format(session_id)
        self.__sendDelete(apiPath, headers=self.headers)

    def delete_current_session(self):
        """
        Delete the current session
        return: None
        """
        apiPath = '/api/v2/sessions/{}'.format(self.sessionID)
        self.__sendDelete(apiPath, headers=self.headers)

    def get_all_sessions(self):
        apiPath = '/api/v2/sessions'
        response = self.__sendGet(apiPath, 200).json()
        return response

    def delete_all_sessions(self):
        """
        Delete all the current sessions opened on the application
        :return: None
        """
        print('Deleting all sessions...')
        session_list = self.get_all_sessions()
        for i in range(0, len(session_list)):
            try:
                self.delete_session(session_list[i]['id'])
            except Exception as e:
                print('{} could not be deleted  because: {}'.format(session_list[i]['id'], e))
                pass
        if len(self.get_all_sessions()) > 0:
            raise Exception('Not all sessions could be deleted!')
        else:
            print('No sessions opened!')

    def get_test_details(self, session_id):
        apiPath = '/api/v2/sessions/{}/test'.format(session_id)
        response = self.__sendGet(apiPath, 200).json()
        return response

    def set_license_server(self, licenseServerIP, retries=3, wait=30):
        apiPath = '/api/v2/license-servers'
        self.__sendPost(apiPath, payload={"hostName": licenseServerIP})

    def get_license_servers(self):
        apiPath = '/api/v2/license-servers'
        return self.__sendGet(apiPath, 200).json()

    def wait_event_success(self, apiPath, timeout):
        counter = 1
        while timeout > 0:
            response = self.__sendGet(apiPath, 200).json()
            if response['state'] == "SUCCESS":
                return response
            else:
                timeout -= counter
                time.sleep(counter)

    def activate_license(self, activation_code, quantity=1, timeout=60):
        apiPath = '/api/v2/licensing/operations/activate'
        response = self.__sendPost(apiPath, payload=[{"activationCode": activation_code, "quantity": quantity}]).json()
        apiPath = '/api/v2/licensing/operations/activate/{}'.format(response["id"])
        if not self.wait_event_success(apiPath, timeout):
            raise TimeoutError("Failed to activate license. Timeout reached = {} seconds".format(timeout))

    def deactivate_license(self, activation_code, quantity=1, timeout=60):
        apiPath = '/api/v2/licensing/operations/deactivate'
        response = self.__sendPost(apiPath, payload=[{"activationCode": activation_code, "quantity": quantity}]).json()
        apiPath = '/api/v2/licensing/operations/deactivate/{}'.format(response["id"])
        if "The Activation Code : \'{}\' is not installed.".format(activation_code) == \
                self.__sendGet(apiPath, 200).json()['message']:
            print('License code {} is not installed'.format(activation_code))
        elif not self.wait_event_success(apiPath, timeout):
            raise TimeoutError("Failed to deactivate license. Timeout reached = {} seconds".format(timeout))

    def get_license_statistics(self, timeout=30):
        apiPath = '/api/v2/licensing/operations/retrieve-counted-feature-stats'
        response = self.__sendPost(apiPath, payload={}).json()
        apiPath = '/api/v2/licensing/operations/retrieve-counted-feature-stats/{}'.format(response["id"])
        if not self.wait_event_success(apiPath, timeout):
            raise TimeoutError("Failed to obtain license stats. Timeout reached = {} seconds".format(timeout))
        apiPath = '/api/v2/licensing/operations/retrieve-counted-feature-stats/{}/result'.format(response["id"])
        response = self.__sendGet(apiPath, 200).json()
        return response

    def nats_update_route(self, nats_address, retries=3, wait=120):
        apiPath = '/api/v2/brokers'
        self.__sendPost(apiPath, payload={"host": nats_address})

    def import_config(self, config):
        apiPath = '/api/v2/configs'
        if config.endswith('.json'):
            config = json.loads(open(config, "r").read())
            response = self.__sendPost(apiPath, config)
        elif config.endswith('.zip'):
            zip_file_path = {"archive": (config, open(config, "rb"), "application/zip")}
            response = self.__sendPost(apiPath, None, customHeaders=self.headers, files=zip_file_path)
        else:
            raise Exception("Config type not supported. Requires zip or json.")
        if response:
            print('Config successfully imported, config ID: {}'.format(response.json()[0]['id']))
            return response.json()[0]['id']
        else:
            raise Exception('Failed to import test config')

    def export_config(self, export_path=None):
        config_id = self.configID
        apiPath = '/api/v2/configs/{}?include=all&resolveDependencies=true'.format(config_id)
        customHeaders = self.headers
        customHeaders['Accept'] = 'application/zip'
        response = self.__sendGet(apiPath, 200, customHeaders=customHeaders)

        file_name = response.headers.get('content-disposition').split("=")[1].strip('"')

        if export_path:
            file_name = os.path.join(export_path, file_name)
        print("Export path/file: {}".format(file_name))
        with open(file_name, 'wb') as archive:
            archive.write(response.content)
        return file_name

    def export_config_by_name(self, export_path=None, config_name=None):
        config_id = self.get_config_id(config_name)
        apiPath = '/api/v2/configs/{}?include=all&resolveDependencies=true'.format(config_id)
        customHeaders = self.headers
        customHeaders['Accept'] = 'application/zip'
        response = self.__sendGet(apiPath, 200, customHeaders=customHeaders)

        file_name = response.headers.get('content-disposition').split("=")[1].strip('"')

        if export_path:
            file_name = os.path.join(export_path, file_name)
        print("Export path/file: {}".format(file_name))
        with open(file_name, 'wb') as archive:
            archive.write(response.content)
        return file_name

    def open_config(self):
        apiPath = '/api/v2/sessions/'
        response = self.__sendPost(apiPath, payload={"configUrl": self.configID})
        if response:
            print('Config successfully opened, session ID: {}'.format(response.json()[0]['id']))
            return response.json()[0]['id']

    def get_session_config(self, sessionId=None):
        sessionId = sessionId if sessionId else self.sessionID
        apiPath = '/api/v2/sessions/{}/config?include=all'.format(sessionId)
        return self.__sendGet(apiPath, 200, debug=False).json()

    def delete_config(self, config_id):
        """
        Delete a config after you've specified its id
        :param config_id: The id of the config
        :return: None
        """
        apiPath = '/api/v2/configs/{}'.format(config_id)
        self.__sendDelete(apiPath, self.headers)

    def delete_config_by_name(self, config_name=None):
        config_id = self.get_config_id(config_name)
        apiPath = '/api/v2/configs/{}'.format(config_id)
        self.__sendDelete(apiPath, self.headers)

    def add_network_segment(self):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment'.format(self.sessionID)
        self.__sendPost(apiPath, {})

    def wait_agents_connect(self, agents_nr=3, timeout=300):
        response = []
        init_timeout = timeout
        print('Waiting for agents to connect to the CyPerf controller...')
        while timeout > 0:
            response = self.get_agents()
            if len(response) >= agents_nr:
                print('There are {} agents connected to the CyPerf controller'.format(len(response)))
                return True
            else:
                time.sleep(10)
                timeout -= 10
        else:
            raise Exception(
                "Expected {} agents connected after {}s. Got only {}.".format(agents_nr, init_timeout, len(response)))

    def get_agents(self):
        apiPath = '/api/v2/agents'
        return self.__sendGet(apiPath, 200).json()

    def get_agents_ids(self, agentIPs=None, wait=None):
        if wait:
            self.wait_agents_connect()
        agentsIDs = list()
        response = self.get_agents()
        print('Found {} agents'.format(len(response)))
        if type(agentIPs) is str: agentIPs = [agentIPs]
        for agentIP in agentIPs:
            for agent in response:
                if agent['IP'] in agentIP:
                    print("agent_IP: {}, agent_ID: {}".format(agent['IP'], agent['id']))
                    agentsIDs.append(agent['id'])
                    break
        return agentsIDs

    def get_agents_ips(self, wait=None):
        if wait:
            self.wait_agents_connect()
        agentsIPs = list()
        response = self.get_agents()
        print('Found {} agents'.format(len(response)))
        # fixme B2B only - ClientAgent is excluded in AWS scenario
        for agent in response:
            agentsIPs.append(agent['IP'])
        print('Agents IP List: {}'.format(agentsIPs))
        return agentsIPs

    def assign_agents(self):
        agents_ips = self.get_agents_ips()
        self.assign_agents_by_ip(agents_ips=agents_ips[0], network_segment=1)
        self.assign_agents_by_ip(agents_ips=agents_ips[1], network_segment=2)

    def assign_agents_by_ip(self, agents_ips, network_segment):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/agentAssignments'.format(
            self.sessionID, network_segment)
        payload = {"ByID": [], "ByTag": []}
        agents_ids = self.get_agents_ids(agentIPs=agents_ips)
        for agent_id in agents_ids:
            payload["ByID"].append({"agentId": agent_id})
        self.__sendPatch(apiPath, payload)

    def assign_agents_by_tag(self, agents_tags, network_segment):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/agentAssignments'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"ByID": [], "ByTag": [agents_tags]})

    def set_traffic_capture(self, agents_ips, network_segment, is_enabled=True, capture_latest_packets=False,
                            max_capture_size=104857600):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/agentAssignments'.format(
            self.sessionID, network_segment)
        payload = {"ByID": []}
        capture_settings = {"captureEnabled": is_enabled, "captureLatestPackets": capture_latest_packets,
                            "maxCaptureSize": max_capture_size}
        agents_ids = self.get_agents_ids(agentIPs=agents_ips)
        for agent_id in agents_ids:
            payload["ByID"].append({"agentId": agent_id, "captureSettings": capture_settings})
        self.__sendPatch(apiPath, payload)

    def get_capture_files(self, captureLocation, exportTimeout=180):
        self.get_result_ended()
        test_id = self.get_test_id()
        apiPath = '/api/v2/results/{}/operations/generate-results'.format(test_id)
        response = self.__sendPost(apiPath, None).json()
        apiPath = response['url'][len(self.host):]
        response = self.wait_event_success(apiPath, timeout=exportTimeout)
        if not response:
            raise TimeoutError("Failed to download Captures. Timeout reached = {} seconds".format(exportTimeout))
        apiPath = response['resultUrl']
        response = self.__sendGet(apiPath, 200, debug=False)
        zf = ZipFile(io.BytesIO(response.content), 'r')
        zf.extractall(captureLocation)
        for arh in glob.iglob(os.path.join(captureLocation, "*.zip")):
            files = os.path.splitext(os.path.basename(arh))[0]
            zf = ZipFile(arh)
            zf.extractall(path=os.path.join(captureLocation, "pcaps", files))
        return response

    def get_pdf_report(self, pdfLocation, exportTimeout=180):
        test_id = self.get_test_id()
        apiPath = '/api/v2/results/{}/operations/generate-pdf'.format(test_id)
        response = self.__sendPost(apiPath, None).json()
        apiPath = response['url'][len(self.host):]
        response = self.wait_event_success(apiPath, timeout=exportTimeout)
        if not response: 
            raise TimeoutError("Failed to download PDF report. Timeout reached = {} seconds".format(exportTimeout))
        apiPath = response['resultUrl']
        with open(pdfLocation, "wb") as f:
            response = self.__sendGet(apiPath, 200, debug=False)
            if response.status_code == 200:
                pdf_response_content = response.content
                f.write(pdf_response_content)
        return response            

    def add_dut(self):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        return response

    def delete_dut(self, network_segment):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendDelete(apiPath, self.headers)

    def set_dut(self, active=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendPatch(apiPath, payload={"active": active})

    def set_dut_host(self, host, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendPatch(apiPath, payload={"host": host})

    def set_http_health_check(self, enabled=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Enabled": enabled})

    def set_http_health_check_port(self, port, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Port": port})

    def set_http_health_check_url(self, target_url, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath + '/Params/1', payload={"Value": target_url})

    def set_http_health_check_payload(self, payload_file, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        if isinstance(payload_file, float):
            self.__sendPatch(apiPath + '/Params/2', payload={"Value": payload_file})
        else:
            self.set_custom_payload(apiPath + '/Params/2', payload_file)

    def set_http_health_check_version(self, http_version, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath + '/Params/3', payload={"Value": http_version})

    def set_https_health_check(self, enabled=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPSHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Enabled": enabled})

    def set_https_health_check_port(self, port, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPSHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Port": port})

    def set_https_health_check_url(self, target_url, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPSHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath + '/Params/1', payload={"Value": target_url})

    def set_https_health_check_payload(self, payload_file, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPSHealthCheck'.format(
            self.sessionID, network_segment)
        if isinstance(payload_file, float):
            self.__sendPatch(apiPath + '/Params/2', payload={"Value": payload_file})
        else:
            self.set_custom_payload(apiPath + '/Params/2', payload_file)

    def set_https_health_check_version(self, https_version, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/HTTPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath + '/Params/3', payload={"Value": https_version})

    def set_tcp_health_check(self, enabled=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/TCPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Enabled": enabled})

    def set_tcp_health_check_port(self, port, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}/TCPHealthCheck'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Port": port})

    def set_client_recieve_buffer_size_attack_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/1/TrafficSettings/DefaultTransportProfile/ClientTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"RxBuffer": value})

    def set_client_transmit_buffer_size_attack_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/1/TrafficSettings/DefaultTransportProfile/ClientTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"TxBuffer": value})

    def set_client_recieve_buffer_size_traffic_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ClientTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"RxBuffer": value})

    def set_client_transmit_buffer_size_traffic_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ClientTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"TxBuffer": value})

    def set_server_recieve_buffer_size_attack_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/1/TrafficSettings/DefaultTransportProfile/ServerTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"RxBuffer": value})

    def set_server_transmit_buffer_size_attack_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/1/TrafficSettings/DefaultTransportProfile/ServerTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"TxBuffer": value})

    def set_server_recieve_buffer_size_traffic_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ServerTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"RxBuffer": value})

    def set_server_transmit_buffer_size_traffic_profile(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ServerTcpProfile'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"TxBuffer": value})

    def set_ip_network_segment(self, active=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}'.format(self.sessionID,
                                                                                                   network_segment)
        self.__sendPatch(apiPath, payload={"active": active})

    def set_network_tags(self, tags="Client", network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}'.format(self.sessionID,
                                                                                                   network_segment)
        self.__sendPatch(apiPath, payload={"networkTags": [tags]})

    def set_application_client_network_tags(self, tags, app_nr):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/Applications/{}/operations/modify-tags-recursively'.format(
            self.sessionID, app_nr)
        self.__sendPost(apiPath, payload={"SelectTags": True, "ClientNetworkTags": [tags]})

    def remove_application_client_network_tags(self, tags, app_nr):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/Applications/{}/operations/modify-tags-recursively'.format(
            self.sessionID, app_nr)
        self.__sendPost(apiPath, payload={"SelectTags": False, "ClientNetworkTags": [tags]})

    def set_network_min_agents(self, min_agents=1, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}'.format(self.sessionID,
                                                                                                   network_segment)
        self.__sendPatch(apiPath, payload={"minAgents": min_agents})

    def add_ip_range(self, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges'.format(
            self.sessionID, network_segment)
        response = self.__sendPost(apiPath, payload={}).json()
        return response[-1]['id']

    def delete_ip_range(self, ip_range=1, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendDelete(apiPath, self.headers)

    def set_ip_range_automatic_ip(self, ip_auto=True, network_segment=1, ip_range=1, ):
        
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"IpAuto": ip_auto})

    def set_ip_range_ip_start(self, ip_start, network_segment=1, ip_range=1, ):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"IpStart": ip_start})

    def set_ip_range_ip_increment(self, ip_increment="0.0.0.1", network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"IpIncr": ip_increment})

    def set_ip_range_ip_count(self, count=1, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"Count": count})

    def set_ip_range_max_count_per_agent(self, max_count_per_agent=1, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"maxCountPerAgent": max_count_per_agent})

    def set_ip_range_automatic_netmask(self, netmask_auto=True, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"NetMaskAuto": netmask_auto})

    def set_ip_range_netmask(self, netmask=16, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"NetMask": netmask})

    def set_ip_range_automatic_gateway(self, gateway_auto=True, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"GwAuto": gateway_auto})

    def set_ip_range_gateway(self, gateway="10.0.0.1", network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"GwStart": gateway})

    def set_ip_range_network_tags(self, tags, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"networkTags": [tags]})

    def set_ip_range_mss(self, mss=1460, network_segment=1, ip_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"Mss": mss})

    def set_eth_range_mac_auto_false(self, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"MacAuto": False})

    def set_eth_range_mac_start(self, mac_start, network_segment=1):
        self.set_eth_range_mac_auto_false(network_segment)
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"MacStart": mac_start})

    def set_eth_range_mac_increment(self, mac_increment, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"MacIncr": mac_increment})

    def set_eth_range_one_mac_per_ip_false(self, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"OneMacPerIP": False})

    def set_eth_range_max_mac_count(self, count, network_segment=1):
        self.set_eth_range_one_mac_per_ip_false(network_segment)
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Count": count})

    def set_eth_range_max_mac_count_per_agent(self, max_count_per_agent, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EthRange'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"maxCountPerAgent": max_count_per_agent})

    def set_dns_resolver(self, name_server, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/DNSResolver'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"nameServers": [{"name": name_server}]})

    def set_dns_resolver_cache_timeout(self, timeout=0, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/DNSResolver'.format(
            self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"cacheTimeout": timeout})

    def set_dut_connections(self, connections, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}'.format(self.sessionID,
                                                                                                   network_segment)
        self.__sendPatch(apiPath, payload={"DUTConnections": connections})

    def set_profile_duration(self, profile_type, value):
        apiPath = '/api/v2/sessions/{}/config/config/{}/1/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, profile_type)
        self.__sendPatch(apiPath, payload={"Duration": value})

    def get_iteration_count_info(self, ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, ap_id)
        config_type = self.get_config_type()
        if config_type["traffic"]:
            print('Parameter not available in traffic profile')
        if config_type["attack"]:
            response = self.__sendGet(apiPath, 200).json()
            return response["IterationCount"]

    def get_profile_duration(self, profile_type):
        apiPath = '/api/v2/sessions/{}/config/config/{}/1/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, profile_type)
        response = self.__sendGet(apiPath, 200).json()
        return response["Duration"]

    def set_test_duration(self, value):
        config_type = self.get_config_type()
        if config_type["traffic"]:
            self.set_profile_duration(profile_type='TrafficProfiles', value=int(value))
        if config_type["attack"]:
            self.set_profile_duration(profile_type='AttackProfiles', value=int(value))
        self.testDuration = int(value)

    def read_test_duration(self):
        TrafficProfilesDuration = 0
        AttackProfilesDuration = 0
        config_type = self.get_config_type()
        if config_type["traffic"]:
            TrafficProfilesDuration = self.get_profile_duration(profile_type='TrafficProfiles')
        if config_type["attack"]:
            AttackProfilesDuration = self.get_profile_duration(profile_type='AttackProfiles')
        self.testDuration = max(TrafficProfilesDuration, AttackProfilesDuration)

    def send_modified_config(self):
        apiPath = '/api/v2/sessions/{}/config'.format(self.sessionID)
        self.__sendPut(apiPath, self.config)

    def get_config_type(self):
        self.config = self.get_session_config()
        config_type = {"traffic": False,
                       "traffic_profiles": [],
                       "tp_primary_obj": None,
                       "tp_secondary_obj": None,
                       "tp_ssl": False,
                       "attack": False,
                       "attack_profiles": [],
                       "att_obj": False,
                       "at_ssl": False,
                       "dut": False}

        if len(self.config['Config']['TrafficProfiles']) > 0:
            config_type['traffic'] = True
            tp_profiles = self.config['Config']['TrafficProfiles'][0]
            for application in tp_profiles['Applications']:
                if application['ProtocolID'] not in config_type['traffic_profiles']:
                    config_type['traffic_profiles'].append(application['ProtocolID'])
            objectives = tp_profiles['ObjectivesAndTimeline']
            objective_dm = {
                "type": objectives['PrimaryObjective']['Type'],
                "unit": objectives['TimelineSegments'][0]['PrimaryObjectiveUnit'],
                "value": objectives['TimelineSegments'][0]['PrimaryObjectiveValue']
            }
            config_type['tp_primary_obj'] = objective_dm
            if len(objectives['TimelineSegments'][0]['SecondaryObjectiveValues']) > 0:
                objective_dm = {
                    "type": objectives['SecondaryObjectives'][0]['Type'],
                    "unit": objectives['TimelineSegments'][0]['SecondaryObjectiveValues'][0]['Unit'],
                    "value": objectives['TimelineSegments'][0]['SecondaryObjectiveValues'][0]['Value']
                }
                config_type['tp_secondary_obj'] = objective_dm
            if tp_profiles['TrafficSettings']['DefaultTransportProfile']['ClientTLSProfile']['version'] != None:
                config_type['tp_ssl'] = True

        if len(self.config['Config']['AttackProfiles']) > 0:
            config_type['attack'] = True
            at_profiles = self.config['Config']['AttackProfiles'][0]
            for attack in at_profiles['Attacks']:
                if attack['ProtocolID'] not in config_type['attack_profiles']:
                    config_type['attack_profiles'].append(attack['ProtocolID'])
            objective_dm = {
                "attack_rate": at_profiles['ObjectivesAndTimeline']['TimelineSegments'][0]['AttackRate'],
                "max_concurrent_attack": at_profiles['ObjectivesAndTimeline']['TimelineSegments'][0][
                    'MaxConcurrentAttack']
            }
            config_type['att_obj'] = objective_dm
            if at_profiles['TrafficSettings']['DefaultTransportProfile']['ClientTLSProfile']['version'] != None:
                config_type['tp_ssl'] = True

        if self.config['Config']['NetworkProfiles'][0]['DUTNetworkSegment'][0]['active']:
            config_type['dut'] = True
        return config_type

    def start_test(self, initializationTimeout=60):
        apiPath = '/api/v2/sessions/{}/test-run/operations/start'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        self.startTime = self.__getEpochTime()
        startID = response['id']
        print('Start ID : {}'.format(startID))
        progressPath = '/api/v2/sessions/{}/test-run/operations/start/{}'.format(self.sessionID, startID)
        self.__sendGet(progressPath, 200).json()
        counter = 1
        iteration = 0
        while iteration < initializationTimeout:
            response = self.__sendGet(progressPath, 200).json()
            print('Test Progress: {}'.format(response['progress']))
            if response['state'] == 'SUCCESS':
                self.startTrafficTime = self.__getEpochTime()
                return self.startTrafficTime
            if response['state'] == 'ERROR':
                raise Exception('Error when starting the test! {}'.format(self.get_test_details(self.sessionID)))
            iteration += counter
            time.sleep(counter)
        else:
            raise Exception('ERROR! Test could not start in {} seconds, test state: {}'.format(initializationTimeout,
                                                                                               response['state']))

    def stop_test(self):
        apiPath = '/api/v2/sessions/{}/test-run/operations/stop'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        stopID = response['id']
        print('Stop ID : {}'.format(stopID))
        progressPath = '/api/v2/sessions/{}/test-run/operations/stop/{}'.format(self.sessionID, stopID)
        self.__sendGet(progressPath, 200).json()
        counter = 2
        iteration = 0
        while iteration < 60:
            response = self.__sendGet(progressPath, 200).json()
            print('Stop Test Progress: {}'.format(response['progress']))
            if response['state'] == 'SUCCESS':
                break
            if response['state'] == 'ERROR':
                raise Exception('Error when stopping the test! {}'.format(self.get_test_details(self.sessionID)))
            iteration += counter
            time.sleep(counter)

    def get_test_status(self):
        apiPath = '/api/v2/sessions/{}/test'.format(self.sessionID)
        return self.__sendGet(apiPath, 200).json()

    def wait_test_finished(self, timeout=300):
        print('Waiting for the test to finish...')
        response = self.get_test_status()
        actual_duration = 0
        counter = 1
        while actual_duration < self.testDuration + timeout:
            response = self.get_test_status()
            if response['status'] == 'STOPPING' and not self.stopTrafficTime:
                self.stopTrafficTime = self.__getEpochTime()
            if response['status'] == 'STOPPED':
                if response['testElapsed'] >= response['testDuration']:
                    print('Test gracefully finished')
                    self.stopTime = self.__getEpochTime()
                    return self.stopTime
                else:
                    raise Exception("Error! Test stopped before reaching the configured duration = {}; Elapsed = {}"
                                    .format(response['testDuration'], response['testElapsed']))
            else:
                print('Test duration = {}; Elapsed = {}'.format(response['testDuration'], response['testElapsed']))
            actual_duration += counter
            time.sleep(counter)
        else:
            print(
                "Test did not stop after timeout {}s. Test status= {}. Aborting...".format(timeout, response['status']))
            self.stop_test()
            raise Exception("Error! Test was aborted after timeout {}s.".format(timeout))

    @staticmethod
    def __getEpochTime():
        pattern = "%d.%m.%Y %H:%M:%S"
        timeH = datetime.now().strftime(pattern)
        epoch = int(time.mktime(time.strptime(timeH, pattern)))
        return epoch

    def get_test_id(self):
        apiPath = '/api/v2/sessions/{}/test'.format(self.sessionID)
        response = self.__sendGet(apiPath, 200).json()
        return response['testId']

    def get_available_stats_name(self):
        apiPath = '/api/v2/results/{}/stats'.format(self.get_test_id())
        response = self.__sendGet(apiPath, 200).json()
        available_stats = []
        for stat in response:
            available_stats.append(stat['name'])
        return available_stats

    def get_stats_values(self, statName):
        print('Get the values for {}'.format(statName))
        apiPath = '/api/v2/results/{}/stats/{}'.format(self.get_test_id(), statName)
        response = self.__sendGet(apiPath, 200).json()
        return response

    def get_all_stats(self, csvLocation, exportTimeout=180):
        test_id = self.get_test_id()
        apiPath = '/api/v2/results/{}/operations/generate-csv'.format(test_id)
        response = self.__sendPost(apiPath, None).json()
        apiPath = response['url'][len(self.host):]
        response = self.wait_event_success(apiPath, timeout=exportTimeout)
        if not response:
            raise TimeoutError("Failed to download CSVs. Timeout reached = {} seconds".format(exportTimeout))
        apiPath = response['resultUrl']
        response = self.__sendGet(apiPath, 200, debug=False)
        zf = ZipFile(io.BytesIO(response.content), 'r')
        zf.extractall(csvLocation)
        return response

    def get_result_ended(self, timeout=5):
        apiPath = '/api/v2/results/{}'.format(self.get_test_id())
        while timeout > 0:
            print('Pending result availability...')
            response = self.__sendGet(apiPath, 200).json()
            result_end_time = response['endTime']
            result_availability = result_end_time > 0
            if result_availability:
                print('Result may now be downloaded...')
                return result_availability
            else:
                time.sleep(1)
                timeout -= 1
        raise Exception('Result are not available for {}'.format(self.get_test_id()))

    def get_applications(self):
        apiPath = '/api/v2/resources/apps?include=all'
        response = self.__sendGet(apiPath, 200, debug=False).json()
        return response

    def get_attacks(self):
        apiPath = '/api/v2/resources/attacks?include=all'
        response = self.__sendGet(apiPath, 200, debug=False).json()
        return response

    def get_strikes(self):
        apiPath = '/api/v2/resources/strikes?include=all'
        response = self.__sendGet(apiPath, 200).json()
        return response

    def get_application_id(self, app_name):
        app_list = self.get_applications()
        print('Getting application {} ID...'.format(app_name))
        for app in app_list:
            if app['Name'] == app_name:
                print('Application ID = {}'.format(app['id']))
                return app['id']

    def get_strike_id(self, strike_name):
        strike_list = self.get_strikes()
        for strike in strike_list:
            if strike['Name'] == strike_name:
                print('Strike ID = {}'.format(strike['id']))
                return strike['id']

    def get_attack_id(self, attack_name):
        attack_list = self.get_attacks()
        for attack in attack_list:
            if attack['Name'] == attack_name:
                print('Attack ID = {}'.format(attack['id']))
                return attack['id']

    def add_attack(self, attack_name, ap_id=1):
        app_id = self.get_attack_id(attack_name=attack_name)
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks'.format(self.sessionID, ap_id)
        response = self.__sendPost(apiPath, payload={"ExternalResourceURL": app_id}).json()
        return response[-1]['id']

    def add_strike_as_attack(self, strike_name, ap_id=1):
        app_id = self.get_strike_id(strike_name=strike_name)
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks'.format(self.sessionID, ap_id)
        response = self.__sendPost(apiPath, payload={"ProtocolID": app_id}).json()
        return response[-1]['id']

    def add_application(self, app_name, tp_id=1):
        app_id = self.get_application_id(app_name=app_name)
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications'.format(self.sessionID, tp_id)
        response = self.__sendPost(apiPath, payload={"ExternalResourceURL": app_id}).json()
        return response[-1]['id']

    def add_application_action(self, app_id, action_name, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications/{}/Tracks/1/Actions'.format(
            self.sessionID, tp_id, app_id)
        self.__sendPost(apiPath, payload={"Name": action_name}).json()

    def set_application_action_value(self, app_id, action_id, param_id, value, file_value=None, source=None, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications/{}/Tracks/1/Actions/{}/Params/{}'.format(
            self.sessionID, tp_id, app_id, action_id, param_id)
        payload = {"Value": value, "FileValue": file_value, "Source": source}
        self.__sendPatch(apiPath, payload)

    def delete_application_action(self, app_id, action_id, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications/{}/Tracks/1/Actions/{}'.format(
            self.sessionID, tp_id, app_id, action_id)
        self.__sendDelete(apiPath, self.headers)

    def add_attack_action(self, att_id, action_name, ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks/{}/Tracks/1/Actions'.format(
            self.sessionID, ap_id, att_id)
        self.__sendPost(apiPath, payload={"Name": action_name}).json()

    def add_attack_profile(self):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        return response[-1]['id']

    def add_traffic_profile(self):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        return response[-1]['id']

    def set_traffic_profile_timeline(self, duration, objective_value, objective_unit=None, pr_id=1):
        
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, pr_id)
        response = self.__sendGet(apiPath, 200).json()
        payload = {"Duration": duration, "PrimaryObjectiveValue": objective_value}
        self.__sendPatch(apiPath, payload)

    def set_primary_objective(self, objective, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/PrimaryObjective'.format(
            self.sessionID, tp_id)
        self.__sendPut(apiPath, payload={"Type": objective, "Unit": ""})

    def add_primary_objective(self, objective, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/PrimaryObjective'.format(
            self.sessionID, tp_id)
        self.__sendPatch(apiPath, payload={"Type": objective, "Unit": ""})

    def add_secondary_objective(self, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/SecondaryObjectives'.format(
            self.sessionID, tp_id)
        self.__sendPost(apiPath, payload={}).json()

    def add_secondary_objective_value(self, objective, objective_value, objective_unit=None, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/SecondaryObjectives/1'.format(
            self.sessionID, tp_id)
        self.__sendPatch(apiPath, payload={"Type": objective})
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1/SecondaryObjectiveValues/1'.format(
            self.sessionID, tp_id)
        self.__sendPatch(apiPath, payload={"Value": objective_value})
        if objective_unit:
            self.__sendPatch(apiPath, payload={"Unit": objective_unit})
            
    def set_client_http_profile(self, http_profile):
        
        apiPath = "/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ClientHTTPProfile".format(
            self.sessionID
        )
        self.__sendPatch(apiPath, http_profile)

    def set_server_http_profile(self, http_profile):
        apiPath = "/api/v2/sessions/{}/config/config/TrafficProfiles/1/TrafficSettings/DefaultTransportProfile/ServerHTTPProfile".format(
            self.sessionID
        )
        self.__sendPatch(apiPath, http_profile)

    def set_traffic_profile_client_tls(self, version, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/TrafficSettings/DefaultTransportProfile/ClientTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={"version": version})

    def set_traffic_profile_server_tls(self, version, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/TrafficSettings/DefaultTransportProfile/ServerTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={"version": version})

    def set_attack_profile_timeline(self, duration, objective_value, max_concurrent_attacks=None, iteration_count=0,
                                    ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, ap_id)
        payload = {"Duration": duration, "AttackRate": objective_value, "MaxConcurrentAttack": max_concurrent_attacks,
                   "IterationCount": iteration_count}
        self.__sendPatch(apiPath, payload)

    def set_attack_profile_client_tls(self, version, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/TrafficSettings/DefaultTransportProfile/ClientTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={"version": version})

    def set_attack_profile_server_tls(self, version, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/TrafficSettings/DefaultTransportProfile/ServerTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={"version": version})

    def set_custom_payload(self, apiPath, fileName):
        resp = self.__sendPatch(apiPath, payload={"Source": "PayloadProfile"})
        if resp.status_code != 204:
            print("Error patching payload type: {}".format(resp.json()))
        uploadUrl = "/api/v2/resources/payloads"
        payload = self.get_resource(uploadUrl, name=os.path.basename(fileName))
        if not payload:
            payloadFile = open(fileName, 'rb')
            resp = self.__sendPost(uploadUrl, payload=None, customHeaders=self.headers,
                                   files={'file': payloadFile}).json()
            payload = {"FileValue": {"fileName": resp["fileName"], "resourceURL": resp["resourceURL"]}}
        else:
            payload = {"FileValue": {"fileName": payload["name"], "resourceURL": payload["links"][0]["href"]}}
        self.__sendPatch(apiPath, payload=payload)

    def set_application_custom_payload(self, appName, actionName, paramName, fileName):
        config = self.get_session_config()['Config']
        applicationsByName = {app['Name']: app for app in config['TrafficProfiles'][0]['Applications']}
        httpApp = applicationsByName[appName]
        actionsByName = {action['Name']: action for action in httpApp['Tracks'][0]['Actions']}
        postAction = actionsByName[actionName]
        actionParametersByName = {param['Name']: param for param in postAction['Params']}
        bodyParam = actionParametersByName[paramName]
        apiPath = "/api/v2/sessions/{}/config/config/TrafficProfiles/1/Applications/{}/Tracks/1/Actions/{}/Params/{}".format(
            self.sessionID, httpApp['id'], postAction['id'], bodyParam['id']
        )
        self.set_custom_payload(apiPath, fileName)

    def set_custom_playlist(self, apiPath, fileName, value=None):
        resp = self.__sendPatch(apiPath, payload={"Source": "Playlist"})
        if resp.status_code != 204:
            print("Error patching payload type: {}".format(resp.json()))
        uploadUrl = "/api/v2/resources/playlists"
        playlist = self.get_resource(uploadUrl, name=os.path.basename(fileName))
        if not playlist:
            playlistFile = open(fileName, 'rb')
            resp = self.__sendPost(uploadUrl, payload=None, customHeaders=self.headers,
                                   files={'file': playlistFile}).json()
            payload = {"FileValue": {"fileName": resp["fileName"], "resourceURL": resp["resourceURL"]}, "Value": value}
        else:
            payload = {"FileValue": {"fileName": playlist["name"], "resourceURL": playlist["links"][0]["href"]},
                       "Value": value}
        self.__sendPatch(apiPath, payload=payload)

    def set_attack_custom_playlist(self, attackName, actionName, paramName, fileName, value="Query"):
        config = self.get_session_config()['Config']
        attacksByName = {app['Name']: app for app in config['AttackProfiles'][0]['Attacks']}
        attack = attacksByName[attackName]
        actionsByName = {action['Name']: action for action in attack['Tracks'][0]['Actions']}
        postAction = actionsByName[actionName]
        actionParametersByName = {param['Name']: param for param in postAction['Params']}
        bodyParam = actionParametersByName[paramName]
        apiPath = "/api/v2/sessions/{}/config/config/AttackProfiles/1/Attacks/{}/Tracks/1/Actions/{}/Params/{}".format(
            self.sessionID, attack['id'], postAction['id'], bodyParam['id']
        )
        self.set_custom_playlist(apiPath, fileName, value)

    def get_all_configs(self):
        apiPath = '/api/v2/configs'
        response = self.__sendGet(apiPath, 200).json()
        return response

    def get_config_id(self, test_name):
        configs = self.get_all_configs()
        for config in configs:
            if config['displayName'] == test_name:
                print('Config ID = {}'.format(config['id']))
                return config['id']

    def get_resource(self, apiPath, name):
        resp = self.__sendGet(apiPath, 200).json()
        for resource in resp:
            if resource["name"] == name:
                return resource

    def save_config(self, test_name, timeout=10):
        apiPath = '/api/v2/sessions/{}/config/operations/save'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={"Name": test_name}).json()
        apiPath = '/api/v2/sessions/{}/config/operations/save/{}'.format(self.sessionID, response['id'])
        if not self.wait_event_success(apiPath, timeout):
            raise TimeoutError(
                "Could not save copy for test= {}. Timeout reached = {} seconds".format(test_name, timeout))

    def load_config(self, test_name):
        configID = self.get_config_id(test_name=test_name)
        apiPath = '/api/v2/sessions'
        response = self.__sendPost(apiPath, payload={"configUrl": configID}).json()
        if response:
            print('Test= {} was loaded with ID= {}'.format(test_name, response[-1]['id']))
            self.sessionID = response[-1]['id']
            return
        else:
            raise Exception('Failed to load test= {}'.format(test_name))

    def collect_diagnostics(self, timeout=600):
        apiPath = '/api/v2/diagnostics/operations/export'
        response = self.__sendPost(apiPath, payload={"componentList": [], "sessionId": self.sessionID}).json()
        apiPath = '/api/v2/diagnostics/operations/export/{}'.format(response["id"])
        response = self.wait_event_success(apiPath, timeout)

        return response['id']
