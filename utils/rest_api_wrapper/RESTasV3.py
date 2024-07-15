import os
import io
import sys
import glob
import time
import urllib
import urllib3
import requests
import simplejson as json
from zipfile import ZipFile
from datetime import datetime
from requests_toolbelt import MultipartEncoder
sys.path.insert(0, os.path.join(os.path.dirname(__file__)))

from resources.configuration import WAP_USERNAME, WAP_PASSWORD, WAP_CLIENT_ID


class RESTasV3:

    def __init__(self, ipAddress, username=WAP_USERNAME, password=WAP_PASSWORD, verify=True):
        self.ipAddress = ipAddress
        self.username = username
        self.password = password
        self.verify = verify
        self.connect_to_mdw()
        self.startTime = None
        self.startingStartTime = None
        self.configuringStartTime = None
        self.startTrafficTime = None
        self.stopTrafficTime = None
        self.stopTime = None
        self.configID = None
        self.sessionID = None
        self.config = None
        self.app_list = None
        self.strike_list = None
        self.attack_list = None
        self.testDuration = 60

    def connect_to_mdw(self):
        self.session = requests.Session()
        urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
        self.session.verify = False
        self.host = 'https://{}'.format(self.ipAddress)
        self.cookie = self.get_automation_token()
        self.headers = {'authorization': self.cookie}

    def __sendPost(self, url, payload, customHeaders=None, files=None, debug=True):
        expectedResponse = [200, 201, 202, 204]
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
    
    def sendPost(self, url, payload, customHeaders=None, files=None, debug=True):
        expectedResponse = [200, 201, 202, 204]
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

    def sendGet(self, url, expectedResponse, customHeaders=None, debug=True):
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

    def __sendPut(self, url, payload, customHeaders=None, debug=True):
        print("PUT at URL: {} with payload: {}".format(url, payload))
        expectedResponse = [200, 204]
        response = self.session.put('{}{}'.format(self.host, url),
                                    headers=customHeaders if customHeaders else self.headers, data=json.dumps(payload))
        if debug:
            print("PUT response message: {}, response code: {}".format(response.content, response.status_code))
        if response.status_code == 401:
            print('Token has expired, resending request')
            self.refresh_access_token()
            response = self.session.put('{}{}'.format(self.host, url),
                                        headers=customHeaders if customHeaders else self.headers,
                                        data=json.dumps(payload))
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
                   "client_id": WAP_CLIENT_ID}

        response = self.__sendPost(apiPath, payload, customHeaders=headers)
        if self.verify:
            if response.headers.get('content-type') == 'application/json':
                response = response.json()
                print('Access Token: {}'.format(response["access_token"]))
                return response['access_token']
            else:
                raise Exception('Fail to obtain authentication token')
        return response

    def add_new_user(self, **kwargs):
        '''
        A method to add new users to keycloak
        '''
        apiPath = '/auth/admin/realms/keysight/users'

        user_credentials = {"enabled": True,
                            "attributes": {},
                            "groups": [],
                            "emailVerified": "",
                            "username": "luke_cywalker",
                            "email": "perfsaber@lightmail.com",
                            "firstName": "Luke",
                            "lastName": "CyWalker"}
        customHeaders = {"Authorization": f"Bearer {self.cookie}",
                         "Content-Type": "application/json",
                         'Accept': 'application/json'}
        bad_keys = [k for k in kwargs.keys() if k not in user_credentials]
        if not bad_keys:
            user_credentials.update(kwargs)
        new_user = json.dumps(user_credentials)
        response = self.__sendPost(apiPath, payload=new_user, customHeaders=customHeaders)
        print(response.text)
        return response

    def __get_configured_users(self, start_point=0, max_no_of_users_in_resp=20):
        apiPath = f'/auth/admin/realms/keysight/users?briefRepresentation=true&first={start_point}&max={max_no_of_users_in_resp}'
        customHeaders = {"Authorization": f"Bearer {self.cookie}",
                         "Content-Type": "application/json"}
        response = self.__sendGet(apiPath, 200, customHeaders=customHeaders).json()
        return response

    def get_user_id_from_username(self, username):
        configured_users = self.__get_configured_users()
        for user in configured_users:
            if user['username'] == username:
                return user['id']
            else:
                continue
        raise f"{username} is not a configured user on this MDW"

    def change_user_role(self, username, user_role):
        user_id = self.get_user_id_from_username(username)
        apiPath = f"/auth/admin/realms/keysight/users/{user_id}/role-mappings/realm/available"
        customHeaders = {"Authorization": f"Bearer {self.cookie}",
                         "Content-Type": "application/json",
                         'Accept': 'application/json'}
        user_roles = ["cyperf-admin", "cyperf-user", "uma_authorization", "offline_access"]
        if user_role not in user_roles:
            raise f"The role {user_role} you are trying to assign does not exist"
        available_user_roles = self.__sendGet(apiPath, 200, customHeaders=customHeaders).json()
        user_role_payload = []
        for index in range(0, len(available_user_roles)):
            if available_user_roles[index]["name"] == user_role:
                user_role_payload.append(available_user_roles[index])
        apiPath = f"/auth/admin/realms/keysight/users/{user_id}/role-mappings/realm"
        new_role = json.dumps(user_role_payload)
        response = self.__sendPost(apiPath, payload=new_role, customHeaders=customHeaders)
        return response

    def change_user_password(self, username, password):
        user_id = self.get_user_id_from_username(username)
        customHeaders = {"Authorization": f"Bearer {self.cookie}",
                         "Content-Type": "application/json"
                         }
        apiPath = f"/auth/admin/realms/keysight/users/{user_id}/reset-password"
        payload = {"type": "password", "value": password, "temporary": False}
        self.__sendPut(apiPath, payload=payload, customHeaders=customHeaders)

    def delete_user_by_username(self, username):
        apiPath = '/auth/admin/realms/keysight/users'
        configured_users = self.__get_configured_users()
        user_id = ""
        for user in configured_users:
            if user['username'] == username:
                user_id = user['id']
        customHeaders = {"Authorization": f"Bearer {self.cookie}",
                         "Content-Type": "application/json",
                         'Accept': 'application/json'}
        response = self.__sendDelete(apiPath + "/" + user_id, headers=customHeaders)
        return response

    def get_cluster_info(self):
        """
        This method can be used to get versions of all the charts available in the mdw.
        E.g.: self.get_cluster_info()['ati-updates'] will return the ati version currently installed on the mdw machine
        """
        apiPath = '/api/v2/deployment/helm/cluster/releases'
        response = self.__sendGet(apiPath, 200).json()
        charts = {}
        for chart in response:
            charts[chart['name']] = chart['chartDeployment']['chartVersion']
        return charts

    def refresh_access_token(self):
        access_token = self.get_automation_token()
        self.headers = {'authorization': access_token}
        print('Authentication token refreshed!')

    def setup(self, config=None):
        if config:
            self.configID = self.import_config(config)
        else:
            self.configID = "appsec-two-arm-base"
        self.sessionID = self.open_config()
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

    def set_license_server(self, licenseServerIP):
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

    def nats_update_route(self, nats_address):
        apiPath = '/api/v2/brokers'
        self.__sendPost(apiPath, payload={"host": nats_address})

    def upload_package(self, file_path):
        apiPath = '/api/v2/deployment/helm/cluster/staging/operations/add'
        customHeaders = self.headers
        customHeaders['Accept'] = 'application/json'
        mp_encoder = MultipartEncoder(
            fields={
                "packages": ('package', open(file_path, "rb"), 'application/x-tar')
                    }
                )
        customHeaders['content-type'] = mp_encoder.content_type
        response = self.__sendPost(apiPath, payload=mp_encoder, customHeaders=customHeaders).json()
        return response

    def deploy(self, timeout="60m"):
        apiPath = '/api/v2/deployment/helm/cluster/staging/operations/deploy'
        response = self.__sendPost(apiPath, payload={"chartDeployTimeout": timeout,
                                                    "enableAutomatedSystemReboot": True,
                                                    "errorNotResolved": True})
        return response

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
        apiPath = '/api/v2/sessions'
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

    def check_agents_status(self, timeout=60):
        waiting_time = 0
        print('Waiting for agents to be available')
        while True:
            agents_status = [agent['Status'] for agent in self.get_agents()]
            if all(status == 'STOPPED' for status in agents_status):
                if waiting_time <= timeout:
                    print('Agents are available')
                    return True
                else:
                    raise Exception(
                        "The agents were not available for the next test in {}s, but after {}s".format(timeout,
                                                                                                       waiting_time))
            time.sleep(10)
            waiting_time += 10

    def get_agents_ids(self, agentIPs=None, wait=None):
        if wait:
            self.wait_agents_connect()
        agentsIDs = list()
        response = self.get_agents()
        print('Found {} agents'.format(len(response)))
        if type(agentIPs) is str:
            agentIPs = [agentIPs]
        for agentIP in agentIPs:
            for agent in response:
                if agent['IP'] == agentIP:
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

    def assign_agents_by_ip(self, agents_ips, network_segment, ignore_deleted_network_segments=True):
        if not ignore_deleted_network_segments:
            network_segment_id = [network["id"] for network in self.get_session_config()["Config"]["NetworkProfiles"][0]["IPNetworkSegment"]][network_segment-1]
        else:
            network_segment_id = network_segment
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/agentAssignments'.format(
            self.sessionID, network_segment_id)
        payload = {"ByID": [], "ByTag": []}
        agents_ids = self.get_agents_ids(agentIPs=agents_ips)
        for agent_id in agents_ids:
            payload["ByID"].append({"agentId": agent_id})
        self.__sendPatch(apiPath, payload)

    def test_warmup_value(self, value):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/ObjectivesAndTimeline/AdvancedSettings'.format(
            self.sessionID)
        payload = {"WarmUpPeriod": int(value)}
        self.__sendPatch(apiPath, payload)

    def assign_agents_by_tag(self, agents_tags, network_segment, ignore_deleted_network_segments=True):
        if not ignore_deleted_network_segments:
            network_segment_id = [network["id"] for network in self.get_session_config()["Config"]["NetworkProfiles"][0]["IPNetworkSegment"]][network_segment-1]
        else:
            network_segment_id = network_segment
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/agentAssignments'.format(
            self.sessionID, network_segment_id)
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

    def check_if_dut_is_active(self, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        response = self.__sendGet(apiPath, 200).json()
        return response["active"]

    def set_dut_host(self, host, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendPatch(apiPath, payload={"host": host})

    def set_active_dut_configure_host(self, hostname, active=True, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendPatch(apiPath, payload={"active": active, "ServerDUTHost": hostname})

    def set_client_http_proxy(self, host, client_port, connect_mode, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID,
                                                                                                    network_segment)
        self.__sendPatch(apiPath, payload={"active": True})
        self.__sendPatch(apiPath, payload={"ConfigSettings": "ADVANCED_MODE"})
        self.__sendPatch(apiPath, payload={"ClientDUTActive": True})
        self.__sendPatch(apiPath, payload={"ClientDUTHost": host})
        self.__sendPatch(apiPath, payload={"ClientDUTPort": int(client_port)})
        self.__sendPatch(apiPath, payload={"HttpForwardProxyMode": connect_mode})
        self.__sendPatch(apiPath, payload={"ServerDUTActive": False})

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

    def delete_ip_range(self, network_segment=1, ip_range=1):
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
        self.__sendPatch(apiPath, payload={"IpAuto": False})

    def set_ip_range_ip_start_if_enabled(self, ip_start, network_segment=1, ip_range=1, ):
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
        self.__sendPatch(apiPath, payload={"GwAuto": False})

    def set_ip_range_gateway_if_enabled(self, gateway="10.0.0.1", network_segment=1, ip_range=1):
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

    def set_ip_range_vlan(self, vlan_id, vlan_incr, count, count_per_agent, network_segment=1, ip_range = 1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}/InnerVlanRange'.format(
            self.sessionID, network_segment, ip_range)
        self.__sendPatch(apiPath, payload={"VlanEnabled": True})
        self.__sendPatch(apiPath, payload={"VlanId": vlan_id})
        self.__sendPatch(apiPath, payload={"VlanIncr": vlan_incr})
        self.__sendPatch(apiPath, payload={"Count": count})
        self.__sendPatch(apiPath, payload={"CountPerAgent": count_per_agent})
    
    def set_network_segment_name(self, name, network_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}'.format(self.sessionID, network_segment)
        self.__sendPatch(apiPath, payload={"Name":name})

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

    def get_CPUCoresNR(self):
        agent_info = self.get_agents()
        l = [i["cpuInfo"] for i in agent_info]
        count = list(map(len, l))
        return count[0]

    def get_CC_min_value(self, configured_cc_value, agent_cpu_cores):
        favoured_sessions_no = 1  # static value
        global_cc_min_value = 0
        app_info = {}
        config = self.get_session_config()
        traffic_profiles = config['Config']['TrafficProfiles'][0]['Applications']
        total_weight = sum(app['ObjectiveWeight'] for app in traffic_profiles)
        for i in range(len(config['Config']['TrafficProfiles'][0]['Applications'])):
            app_info[i] = {"weight": config['Config']['TrafficProfiles'][0]['Applications'][i]['ObjectiveWeight'],
                           "connections_no": len(
                               config['Config']['TrafficProfiles'][0]['Applications'][i]['Connections'])}
        for app_no, app_details in app_info.items():
            individual_app_cc_value = configured_cc_value * (app_details['weight'] / total_weight)
            individual_app_cc_min_value = min(
                individual_app_cc_value - 2 * app_details['connections_no'] * agent_cpu_cores,
                individual_app_cc_value - min(max(0.1 * individual_app_cc_value, agent_cpu_cores)
                                              , 40 * agent_cpu_cores))
            min_alowed_cc_value = (app_details['connections_no'] * favoured_sessions_no + app_details[
                'connections_no']) * agent_cpu_cores
            global_cc_min_value += int(max(individual_app_cc_min_value, min_alowed_cc_value))
        return global_cc_min_value

    def get_config_type(self):
        self.config = self.get_session_config()
        config_type = {"traffic": False,
                       "traffic_profiles": [],
                       "tls_applications": [],
                       "tp_primary_obj": None,
                       "primary_obj_adv_time_params": [],
                       "tp_secondary_obj": None,
                       "tp_ssl": False,
                       "attack": False,
                       "attack_profiles": [],
                       "tls_attacks": [],
                       "att_obj": False,
                       "at_ssl": False,
                       "dut": False,
                       "tunnel_count_per_outer_ip": None,
                       "redirect_info": {},
                       "ipsec": None,
                       "CPUCoresNr": self.get_CPUCoresNR(),
                       "test_duration": self.testDuration,
                       }
        if len(self.config['Config']['TrafficProfiles']) > 0:
            config_type['traffic'] = True if self.config['Config']['TrafficProfiles'][0]['Active'] else False
            tp_profiles = self.config['Config']['TrafficProfiles'][0]
            redirect_info = {}
            for application in tp_profiles['Applications']:
                if application['ProtocolID'] not in config_type['traffic_profiles']:
                    ###TODO: THIS IS A PROVISORY WORKAROUND BECAUSE CONFIG DOES NOT HOLD INFORMATION OF ENABLED APPS
                    try:
                        if application['Active'] == True:
                            config_type['traffic_profiles'].append(application['ProtocolID'])
                            if application['ClientTLSProfile']['tls12Enabled'] \
                                    or application['ClientTLSProfile']['tls13Enabled']:
                                config_type['tls_applications'].append(application['ProtocolID'])
                    except KeyError:
                        config_type['traffic_profiles'].append(application['ProtocolID'])
                        if application['ClientTLSProfile']['tls12Enabled'] \
                                or application['ClientTLSProfile']['tls13Enabled']:
                            config_type['tls_applications'].append(application['ProtocolID'])
                if application['ProtocolID'] == 'HTTP':
                    for param in application["Params"]:
                        if param["Name"] == 'Follow HTTP Redirects':
                            redirect_info[application['Name']] = param['Value']
            config_type['redirect_info'] = redirect_info
            objectives = tp_profiles['ObjectivesAndTimeline']
            objective_dm = {
                "type": objectives['PrimaryObjective']['Type'],
                "unit": objectives['TimelineSegments'][0]['PrimaryObjectiveUnit'],
                "value": objectives['TimelineSegments'][0]['PrimaryObjectiveValue'],
                "steady_step_duration": objectives['TimelineSegments'][0]['Duration']
            }
            if objectives['PrimaryObjective']['Type'] == "Concurrent connections":
                objective_dm["concurrent_connections_min"] = self.get_CC_min_value(
                    objectives['TimelineSegments'][0]['PrimaryObjectiveValue']
                    , config_type["CPUCoresNr"])
            config_type['tp_primary_obj'] = objective_dm
            advance_timeline_params = [None, None]
            if objectives['PrimaryObjective']['Timeline'][0]['Enabled']:
                step_ramp_up = {
                    "Duration": objectives['PrimaryObjective']['Timeline'][0]["Duration"],
                    "NumberOfSteps": objectives['PrimaryObjective']['Timeline'][0]["NumberOfSteps"],
                }
                advance_timeline_params[0] = step_ramp_up
            if objectives['PrimaryObjective']['Timeline'][2]['Enabled']:
                step_ramp_down = {
                    "Duration": objectives['PrimaryObjective']['Timeline'][2]["Duration"],
                    "NumberOfSteps": objectives['PrimaryObjective']['Timeline'][2]["NumberOfSteps"],
                }
                advance_timeline_params[1] = step_ramp_down
            config_type['primary_objective_adv_time_params'] = advance_timeline_params
            if len(objectives['TimelineSegments'][0]['SecondaryObjectiveValues']) > 0 and len(
                    objectives['SecondaryObjectives']) > 0:
                objective_dm = {
                    "type": objectives['SecondaryObjectives'][0]['Type'],
                    "unit": objectives['TimelineSegments'][0]['SecondaryObjectiveValues'][0]['Unit'],
                    "value": objectives['TimelineSegments'][0]['SecondaryObjectiveValues'][0]['Value']
                }
                if objectives['SecondaryObjectives'][0]['Type'] == "Concurrent connections":
                    objective_dm["concurrent_connections_min"] = self.get_CC_min_value(
                        objectives['TimelineSegments'][0]['SecondaryObjectiveValues'][0]['Value']
                        , config_type["CPUCoresNr"])
                config_type['tp_secondary_obj'] = objective_dm
            if tp_profiles['TrafficSettings']['DefaultTransportProfile']['ClientTLSProfile']['version']:
                config_type['tp_ssl'] = True

        if len(self.config['Config']['AttackProfiles']) > 0:
            config_type['attack'] = True if self.config['Config']['AttackProfiles'][0]['Active'] else False
            at_profiles = self.config['Config']['AttackProfiles'][0]
            for attack in at_profiles['Attacks']:
                if attack['ProtocolID'] not in config_type['attack_profiles']:
                    ###TODO: THIS IS A PROVISORY WORKAROUND BECAUSE CONFIG DOES NOT HOLD INFORMATION OF ENABLED ATTACKS
                    try:
                        if attack['Active'] == True:
                            config_type['attack_profiles'].append(attack['ProtocolID'])
                            if attack['ClientTLSProfile']['tls12Enabled'] \
                                    or attack['ClientTLSProfile']['tls13Enabled']:
                                config_type['tls_attacks'].append(attack['ProtocolID'])
                    except KeyError:
                        config_type['attack_profiles'].append(attack['ProtocolID'])
                        if attack['ClientTLSProfile']['tls12Enabled'] \
                                or attack['ClientTLSProfile']['tls13Enabled']:
                            config_type['tls_attacks'].append(attack['ProtocolID'])
            objective_dm = {
                "attack_rate": at_profiles['ObjectivesAndTimeline']['TimelineSegments'][0]['AttackRate'],
                "max_concurrent_attack": at_profiles['ObjectivesAndTimeline']['TimelineSegments'][0][
                    'MaxConcurrentAttack']
            }
            config_type['att_obj'] = objective_dm
            if at_profiles['TrafficSettings']['DefaultTransportProfile']['ClientTLSProfile']['version']:
                config_type['tp_ssl'] = True

        if self.config['Config']['NetworkProfiles'][0]['DUTNetworkSegment'][0]['active']:
            config_type['dut'] = True

        tunnel_stacks = self.config['Config']['NetworkProfiles'][0]['IPNetworkSegment'][0]['TunnelStacks']
        if len(tunnel_stacks) > 0:
            config_type['tunnel_count_per_outer_ip'] = tunnel_stacks[0]['TunnelRange']['TunnelCountPerOuterIP']

        ipsec_stacks = self.config['Config']['NetworkProfiles'][0]['IPNetworkSegment'][0]['IPSecStacks']
        if len(ipsec_stacks) > 0:
            config_type['ipsec'] = {"host_count_per_tunnel": ipsec_stacks[0]['EmulatedSubConfig']['HostCountPerTunnel'],
                                    "outer_ip_count": ipsec_stacks[0]['OuterIPRange']['Count'],
                                    "rekey_margin": ipsec_stacks[0]["RekeyMargin"],
                                    "lifetime_phase_1": ipsec_stacks[0]["IPSecRange"]["IKEPhase1Config"]["Lifetime"],
                                    "lifetime_phase_2": ipsec_stacks[0]["IPSecRange"]["IKEPhase2Config"]["Lifetime"]}
        return config_type

    def start_test(self, initializationTimeout=600):
        apiPath = '/api/v2/sessions/{}/test-run/operations/start'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        self.startTime = self.__getEpochTime()
        self.read_test_duration()
        print('Waiting for the test to start...')
        response = self.get_test_status()
        actual_duration = 0
        counter = 1
        while actual_duration < initializationTimeout:
            response = self.get_test_status()
            if response['status'] == 'STARTING' and not self.startingStartTime:
                self.startingStartTime = self.__getEpochTime()
            if response['status'] == 'CONFIGURING' and not self.configuringStartTime:
                self.configuringStartTime = self.__getEpochTime()
            if response['status'] == 'STARTED':
                if not self.startTrafficTime:
                    self.startTrafficTime = self.__getEpochTime()
                return self.startTrafficTime
            if response['status'] == 'ERROR':
                raise Exception('Error when starting the test! {}'.format(self.get_test_details(self.sessionID)))
            actual_duration += counter
            time.sleep(counter)
        else:
            raise Exception(
                'ERROR! Test could not start in {} seconds, test state: {}'.format(initializationTimeout, response))

    def stop_test(self, stopTimeout=60):
        apiPath = '/api/v2/sessions/{}/test-run/operations/stop'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        stopID = response['id']
        print('Stop ID : {}'.format(stopID))
        progressPath = '/api/v2/sessions/{}/test-run/operations/stop/{}'.format(self.sessionID, stopID)
        self.__sendGet(progressPath, 200).json()
        counter = 2
        iteration = 0
        while iteration < stopTimeout:
            response = self.__sendGet(progressPath, 200).json()
            print('Stop Test Progress: {}'.format(response['progress']))
            if response['state'] == 'SUCCESS':
                break
            if response['state'] == 'ERROR':
                raise Exception('Error when stopping the test! {}'.format(self.get_test_details(self.sessionID)))
            iteration += counter
            time.sleep(counter)

    def abort_test(self, abortTimeout=60):
        apiPath = '/api/v2/sessions/{}/test-run/operations/abort'.format(self.sessionID)
        response = self.__sendPost(apiPath, payload={}).json()
        stopID = response['id']
        print('Abort ID : {}'.format(stopID))
        progressPath = '/api/v2/sessions/{}/test-run/operations/abort/{}'.format(self.sessionID, stopID)
        self.__sendGet(progressPath, 200).json()
        counter = 2
        iteration = 0
        while iteration < abortTimeout:
            response = self.__sendGet(progressPath, 200).json()
            print('Abort Test Progress: {}'.format(response['progress']))
            if response['state'] == 'SUCCESS':
                break
            if response['state'] == 'ERROR':
                raise Exception('Error when aborting the test! {}'.format(self.get_test_details(self.sessionID)))
            iteration += counter
            time.sleep(counter)

    def get_error_notifications_for_session(self, notif_type="error"):
        apiPath = '/api/v2/notifications?exclude=links&includeSeen=true&severity={}&sessionId={}'.format(notif_type,
                                                                                                         self.sessionID)
        return self.__sendGet(apiPath, 200).json()

    def get_error_notifications_for_test(self, notif_type="error"):
        apiPath = '/api/v2/notifications?exclude=links&includeSeen=true&severity={}&sessionId={}'.format(notif_type,
                                                                                                         self.sessionID)
        error_notifs = self.__sendGet(apiPath, 200).json()
        test_id = self.get_test_id()
        return [notif for notif in error_notifs if "TestId" in notif["tags"] and notif["tags"]["TestId"] == test_id]

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
            print("Test did not stop after timeout {}s. Test status= {}. Force stopping the test!".format(timeout,
                                                                                                          response[
                                                                                                              'status']))
            self.stop_test()
            raise Exception("Error! Test failed to stop after timeout {}s.".format(timeout))

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

    def get_applications_by_pages(self, take=50, skip=0):
        apiPath = '/api/v2/resources/apps?take={}&skip={}&exclude=links'.format(take, skip)
        response = self.__sendGet(apiPath, 200, debug=False).json()
        return response

    def get_configured_applications(self):
        """
        return:  returns a list of tuples containing application name(index 0) / configured app position in UI(index 1)
        """
        configured = self.get_session_config(self.sessionID)
        applications = configured["Config"]["TrafficProfiles"][0]["Applications"]
        configured_applications = [app['Name'] for app in applications]
        apps_in_test = []
        for item in configured_applications:
            application_position = item.split()[-1]
            application_name = " ".join([word for word in item.split() if not word.isdigit()])
            apps_in_test.append((application_name, application_position))
        return apps_in_test

    def switch_application_order(self, new_apps_order):
        """
        Gets current order of the apps and reorders them the same order as the given list.

        :parameter new_apps_order: a list with new indexes representing the new order of the apps.
        :return: list
        """
        configured = self.get_session_config(self.sessionID)
        applications = configured["Config"]["TrafficProfiles"][0]["Applications"]
        reordered_applications = [applications[index] for index in new_apps_order]
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1'.format(self.sessionID)
        self.__sendPatch(apiPath, payload={"Applications": reordered_applications})

    def get_applications_with_filter_applied(self, *args, filter_mode="and", take=50, skip=0):
        filter_by = ",".join(args)
        apiPath = f"/api/v2/resources/apps?take={take}&skip={skip}&exclude=links&searchCol=Name,Description&searchVal={filter_by}&filterMode={filter_mode}"
        result = self.__sendGet(apiPath, 200).json()
        filtered_applications = [(item["Name"], item["Description"]) for item in result["data"]]
        return filtered_applications

    def get_attacks_with_filter_applied(self, *args, filter_mode="and", take=50, skip=0):
        filter_by = ",".join(args)
        apiPath = f"/api/v2/resources/attacks?take={take}&skip={skip}&exclude=links&include=Metadata&searchCol=Name,Description,Direction,Severity,Keywords,References&searchVal={filter_by}&filterMode={filter_mode}"
        result = self.__sendGet(apiPath, 200).json()
        filtered_applications = [
            (item["Name"], item["Description"], item["Metadata"]["Direction"], item["Metadata"]["Severity"]) for item in
            result["data"]]
        return filtered_applications

    def get_attacks(self, filter_by, take=50, skip=0):
        apiPath = f'/api/v2/resources/attacks?take={take}&skip={skip}&exclude=links&include=Metadata&searchCol=Name&searchVal={urllib.parse.quote(filter_by)}&filterMode=and'
        response = self.__sendGet(apiPath, 200, debug=False).json()
        return response

    def get_strikes(self):
        apiPath = '/api/v2/resources/strikes?include=all'
        response = self.__sendGet(apiPath, 200).json()
        return response

    def get_application_id(self, app_name):
        if not self.app_list:
            self.app_list = self.get_applications()
        print('Getting application {} ID...'.format(app_name))
        for app in self.app_list:
            if app['Name'] == app_name:
                print('Application ID = {}'.format(app['id']))
                return app['id']

    def get_strike_id(self, strike_name):
        if not self.strike_list:
            self.strike_list = self.get_strikes()
        for strike in self.strike_list:
            if strike['Name'] == strike_name:
                print('Strike ID = {}'.format(strike['id']))
                return strike['id']

    def get_attack_id(self, attack_name):
        self.attack_list = self.get_attacks(attack_name)
        for attack in self.attack_list["data"]:
            if attack_name in attack['Name']:
                return attack['id']

    def set_agent_optimization_mode(self, mode: str, tp_id=1):
        """
        Configures the agent optimization mode.
        Currently the 2 modes supported:
        RATE_MODE, BALANCED_MODE
        """
        if mode in ["RATE_MODE", "BALANCED_MODE"]:
            apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/AdvancedSettings'.format(
                self.sessionID, tp_id)
            self.__sendPatch(apiPath, payload={"AgentOptimizationMode": mode})
        else:
            raise ValueError("{} is not supported".format(mode))

    def set_attack_warmup_period(self, warmup_period, ap_id=1):
        """
        Sets the warmup period for the Attack profile
        """
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, ap_id)
        self.__sendPatch(apiPath, payload={"WarmUpPeriod": int(warmup_period)})

    def set_traffic_warmup_period(self, warmup_period, tp_id=1):
        """
        Sets the warmup period for the Traffic profile
        """
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/AdvancedSettings'.format(
            self.sessionID, tp_id)
        self.__sendPatch(apiPath, payload={"WarmUpPeriod": int(warmup_period)})

    def add_attack(self, attack_name, ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks'.format(self.sessionID, ap_id)
        if isinstance(attack_name, list):
            payload = []
            for attack in attack_name:
                app_id = self.get_attack_id(attack_name=attack)
                payload.append({"ExternalResourceURL": app_id})
        else:
            app_id = self.get_attack_id(attack_name=attack_name)
            payload = {"ExternalResourceURL": app_id}
        response = self.__sendPost(apiPath, payload=payload).json()
        return response[-1]['id']
    
    def add_add_multiple_attacks_by_id(self, attack_ids,  ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks'.format(self.sessionID, ap_id)
        payload = [{"ExternalResourceURL": attack_id} for attack_id in attack_ids] 
        response = self.__sendPost(apiPath, payload=payload).json()
        return response[-1]['id']

    def add_strike_as_attack(self, strike_name, ap_id=1):
        app_id = self.get_strike_id(strike_name=strike_name)
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks'.format(self.sessionID, ap_id)
        response = self.__sendPost(apiPath, payload={"ProtocolID": app_id}).json()
        return response[-1]['id']

    def create_customized_attack(self, application_name, strike_name, insert_at_position):
        app_id = self.get_application_id(app_name=application_name)
        api_path = '/api/v2/sessions/{}/config/config/AttackProfiles/1/Attacks/operations/create'.format(self.sessionID)
        payload = {"Actions": [{"ProtocolID": strike_name, "InsertAtIndex": insert_at_position}],
                   "ResourceURL": f'api/v2/resources/apps/{app_id}'}
        response = self.__sendPost(api_path, payload=payload).json()
        status_url = response["url"].split("/")[-1]
        api_path = '/api/v2/sessions/{}/config/config/AttackProfiles/1/Attacks/operations/create/{}'.format(
            self.sessionID, status_url)
        for index in range(10):
            response = self.__sendGet(api_path, 200).json()
            time.sleep(1)
            if response["state"] == "SUCCESS":
                return
            else:
                continue
        raise Exception("Application action was not added after 10 seconds")

    def add_customize_attack_by_id(self, id_list, timeout=60):
        api_path = f"/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/operations/create"
        payload = {"Actions": [{"ProtocolID": strike_id} for strike_id in id_list]}
        response = self.__sendPost(api_path, payload=payload).json()
        while timeout > 0:
            if self.__sendGet(f"{api_path}/{response['id']}", 200).json()["state"] == 'SUCCESS':
                return response
            time.sleep(1)
            timeout-=1
        raise Exception(f"Couldn't add al the attacks within {timeout} seconds")

    def rename_custom_attack(self, name, index=1):
         api_path = f"/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{index}"
         payload = {"Name": name}
         response = self.__sendPatch(api_path, payload=payload)
         return response

    def insert_attack_action_at_exact_position(self, attack_id, action_id, insert_at_position):
        api_path = f'/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack_id}/Tracks/1/operations/add-actions'
        response = self.__sendPost(api_path, payload={
            "Actions": [{"ActionID": action_id, "InsertAtIndex": insert_at_position}]}).json()
        status_url = response["url"].split("/")[-1]
        api_path = f'/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack_id}/Tracks/1/operations/add-actions/{status_url}'
        for index in range(10):
            response = self.__sendGet(api_path, 200).json()
            time.sleep(1)
            if response["state"] == "SUCCESS":
                return response["result"][insert_at_position]["id"]
            else:
                continue

    def add_application(self, app_name, tp_id=1):
        app_id = self.get_application_id(app_name=app_name)
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications'.format(self.sessionID, tp_id)
        response = self.__sendPost(apiPath, payload={"ExternalResourceURL": app_id}).json()
        return response[-1]['id']

    def insert_application_at_action_exact_position(self, app_id, action_id, position):
        api_path = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}/Tracks/1/operations/add-actions'
        response = self.__sendPost(api_path,
                                   payload={"Actions": [{"ActionID": action_id, "InsertAtIndex": position}]}).json()
        status_url = response["url"].split("/")[-1]
        api_path = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}/Tracks/1/operations/add-actions/{status_url}'
        for index in range(10):
            response = self.__sendGet(api_path, 200).json()
            time.sleep(1)
            if response["state"] == "SUCCESS":
                return response["result"][position]["id"]
            else:
                continue
        raise Exception("Application action was not added after 10 seconds")

    def add_application_action(self, app_id, action_name, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications/{}/Tracks/1/Actions'.format(
            self.sessionID, tp_id, app_id)
        self.__sendPost(apiPath, payload={"Name": action_name}).json()

    def set_attack_action_value(self, attack_id, action_index, value, tp_id=1, param_id=0):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/Attacks/{}/Tracks/1/Actions/{}/Params/{}'.format(
            self.sessionID, tp_id, attack_id, action_index, param_id)
        self.__sendPatch(apiPath, payload= {"Value": value})

    def set_application_action_value(self, app_id, action_id, param_id, value, file_value=None, source=None, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/Applications/{}/Tracks/1/Actions/{}/Params/{}'.format(
            self.sessionID, tp_id, app_id, action_id, param_id)
        payload = {"Value": value, "FileValue": file_value, "Source": source}
        self.__sendPatch(apiPath, payload)

    def get_application_actions(self, app_id):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}/Tracks/1/Actions'
        response = self.__sendGet(apiPath, 200, debug=False).json()
        return response

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
        payload = {"Duration": duration, "PrimaryObjectiveValue": objective_value,
                   "PrimaryObjectiveUnit": objective_unit}
        self.__sendPatch(apiPath, payload)

    def set_application_simulated_users_timeline(self, max_su_per_second, max_pending_su, objective_unit=None, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/1/ObjectivesAndTimeline/PrimaryObjective'.format(
            self.sessionID)
        payload = {"MaxSimulatedUsersPerInterval": max_su_per_second, "MaxPendingSimulatedUsers": max_pending_su}
        self.__sendPatch(apiPath, payload)

    def set_primary_objective(self, objective, tp_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/ObjectivesAndTimeline/PrimaryObjective'.format(
            self.sessionID, tp_id)
        self.__sendPatch(apiPath, payload={"Type": objective, "Unit": ""})

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

    def set_traffic_profile_client_tls(self, version, status, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/TrafficSettings/DefaultTransportProfile/ClientTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={version: status})

    def set_traffic_profile_server_tls(self, version, status, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/TrafficProfiles/{}/TrafficSettings/DefaultTransportProfile/ServerTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={version: status})

    def set_attack_profile_timeline(self, duration, objective_value, max_concurrent_attacks=None, iteration_count=0,
                                    ap_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/ObjectivesAndTimeline/TimelineSegments/1'.format(
            self.sessionID, ap_id)
        payload = {"Duration": duration, "AttackRate": objective_value, "MaxConcurrentAttack": max_concurrent_attacks,
                   "IterationCount": iteration_count}
        self.__sendPatch(apiPath, payload)

    def set_attack_profile_client_tls(self, version, status, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/TrafficSettings/DefaultTransportProfile/ClientTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={version: status})

    def set_attack_profile_server_tls(self, version, status, pr_id=1):
        apiPath = '/api/v2/sessions/{}/config/config/AttackProfiles/{}/TrafficSettings/DefaultTransportProfile/ServerTLSProfile'.format(
            self.sessionID, pr_id)
        self.__sendPatch(apiPath, payload={version: status})

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
            payload = {"FileValue": {"fileName": resp["fileName"], "resourceURL": resp["resourceURL"], "Value": value}}
        else:
            payload = {"FileValue": {"fileName": playlist["name"], "resourceURL": playlist["links"][0]["href"],
                                     "Value": value}}
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

    def set_diagnostics_level(self, log_level):
        apiPath = '/api/v2/log-config'
        response = self.__sendPut(apiPath, payload={"level": log_level})

        return response

    def add_tunnel_stack(self, network_segment_number=1):
        """
        Add a tunnel stack
        """
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/NetworkProfiles/1/IPNetworkSegment/{network_segment_number}/TunnelStacks'
        self.__sendPost(apiPath, payload={})

    def get_tunnel_stack(self):
        """
        Obtain information about tunnel stack configuration on client.
        """
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/NetworkProfiles/1/IPNetworkSegment/1/TunnelStacks'
        return self.__sendGet(apiPath, 200).json()

    def get_tunnel_outer_ip(self):
        """
        Obtain information about tunnel stack configuration on client.
        """
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/NetworkProfiles/1/IPNetworkSegment/1/TunnelStacks/1/OuterIPRange'
        return self.__sendGet(apiPath, 200).json()

    def set_tunnel_stack_gateway_vpn_ip(self, tunnel_type, gw_vpn_ip, network_segment_number=1):
        """
        Set the value for VPN gateway IP.

        :params tunnel_type: (str) CiscoAnyConnectSettings, FortinetSettings, PANGPSettings
        """
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/NetworkProfiles/1/IPNetworkSegment/{network_segment_number}/TunnelStacks/1/TunnelRange/{tunnel_type}'
        response = self.get_tunnel_stack()
        if response:
            self.__sendPatch(apiPath, payload={"VPNGateway": gw_vpn_ip})
        else:
            self.add_tunnel_stack()
            self.__sendPatch(apiPath, payload={"VPNGateway": gw_vpn_ip})

    def set_tunnel_stack_type(self, tunnel_type, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"VendorType": tunnel_type})

    def set_tunnel_count(self, number_of_tunnels, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange'.format(
            self.sessionID, network_segment_number)
        resp = self.__sendPatch(apiPath, payload={"TunnelCountPerOuterIP": int(number_of_tunnels)})
        if resp.status_code != 204:
            print("Error setting VPN tunnel count per outer IP: {}".format(resp.json()))

    def set_tunnel_establisment_timeout(self, tunnel_timeout, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"TunnelEstablishmentTimeout": tunnel_timeout})

    def set_pan_tunnel_portal_hostname(self, portal_hostname, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/PANGPSettings'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"PortalHostname": portal_hostname})

    def set_tunnel_pan_vpn_gateways(self, tunnel_type, vpn_gateways, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/{}'.format(
            self.sessionID, network_segment_number, tunnel_type)
        self.__sendPatch(apiPath, payload={"VPNGateways": list(vpn_gateways.split(" "))})

    def set_tunnel_cisco_vpn_gateway(self, tunnel_type, vpn_gateways, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/{}'.format(
            self.sessionID, network_segment_number, tunnel_type)
        self.__sendPatch(apiPath, payload={"VPNGateway": vpn_gateways})

    def set_tunnel_cisco_connection_profiles(self, connection_profiles, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/CiscoAnyConnectSettings'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"ConnectionProfiles": list(connection_profiles.split(" "))})

    def set_tunnel_auth_settings(self, tunnel_type, field, value, source, network_segment_number=1):
        # Field can be UsernamesParam or PasswordsParam
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/{}/AuthSettings/{}'.format(
            self.sessionID, network_segment_number, tunnel_type, field)
        self.__sendPatch(apiPath, payload={"Value": value, "Source": source})

    def set_tunnel_outer_ip_gateway(self, gateway_ip, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/OuterIPRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"GwAuto": False})
        resp = self.__sendPatch(apiPath, payload={"GwStart": gateway_ip})
        if resp.status_code != 204:
            print("Error network tags in Inncer IP range: {}".format(resp.json()))

    def set_tunnel_automatic_gateway(self, gateway_auto=True, network_segment=1, tunnel_stack=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment, tunnel_stack)
        self.__sendPatch(apiPath, payload={"GwAuto": gateway_auto})

    def set_tunnel_outer_ip_range(self, ip_start, count, max_count, network_segment_number=1, ip_incr="0.0.0.1"):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/OuterIPRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"IpAuto": False})
        self.__sendPatch(apiPath, payload={"IpStart": ip_start})
        self.__sendPatch(apiPath, payload={"IpIncr": ip_incr})
        self.__sendPatch(apiPath, payload={"Count": count})
        self.__sendPatch(apiPath, payload={"maxCountPerAgent": max_count})

    def set_tunnel_outer_ip_start(self, ip_start, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/OuterIPRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"IpStart": ip_start})

    def set_tunnel_stack_dns_servers(self, servers, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/DNSResolver'.format(
            self.sessionID, network_segment_number)
        serverList = list(map(lambda x: {"name": x}, list(servers.split(","))))
        self.__sendPatch(apiPath, payload={"nameServers": serverList})

    def delete_ip_stack(self, network_segment_number=1, ip_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment_number, ip_stack_number)
        self.__sendDelete(apiPath, self.headers)

    def set_tunnel_inner_ip_network_tags(self, network_tags, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/InnerIPRange'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"networkTags": network_tags})

    def set_tunnel_udp_port(self, tunnel_type, encapsulation_type, udp_port, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/1/TunnelRange/{}/{}'.format(
            self.sessionID, network_segment_number, tunnel_type, encapsulation_type)
        self.__sendPatch(apiPath, payload={"UdpPort": udp_port})

    def __get_status_for_advance_timeline(self):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/ObjectivesAndTimeline/PrimaryObjective/Timeline'
        result = self.__sendGet(apiPath, 200)
        return result.json()

    def get_specific_value_from_given_ramp_segment(self, segment_type, given_key):
        acceptable_keys = ["Duration", "SegmentType", "Enabled", "AutomaticObjectiveValue", "NumberOfSteps",
                           "PrimaryObjectiveValue", "SecondaryObjectiveValues", "ObjectiveValue", "ObjectiveUnit"]
        if given_key not in acceptable_keys:
            raise Exception(f"Cannot find key {given_key}, make sure the key exists in this list {acceptable_keys}")
        response = self.__get_status_for_advance_timeline()
        return response[segment_type - 1][given_key]

    def enable_step_ramp_down_or_up(self, segment_type=None):
        """
        A method to activate the step ramp-up feature

        :params segment_type: default set to enable for both ramp up or down, could receive a string "up"/"down" if
        ...  only one segment is to be enabled.
        """
        if segment_type:
            self.__setStepRamp(True, segment_type)
        else:
            for segment in [1, 3]:
                self.__setStepRamp(True, segment)

    def disable_step_ramp_down_or_up(self, segment_type=None):
        """
        A method to activate the step ramp-up feature

        :params segment_type:  default set to enable for both ramp up or down, could receive a string "up"/"down" if
        ...  only one segment is to be enabled.
        """
        if segment_type:
            self.__setStepRamp(False, segment_type)
        else:
            for segment in [1, 3]:
                self.__setStepRamp(False, segment)

    def __setStepRamp(self, action, segment_type):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/ObjectivesAndTimeline/PrimaryObjective/Timeline/{segment_type}'
        self.__sendPatch(apiPath, payload={"Enabled": action})

    def set_specific_value_for_given_ramp_segment(self, segment_type, key, value):
        """
        A method to set different parameters at the timeline segment

        :params key: one of the endpoint keys, must fit in the acceptable_keys list
        :params value: any value
        :params segment_type: specify which one of the RampUpDown segment to use must be "UP" / "DOWN"
        """
        acceptable_keys = ["Duration", "NumberOfSteps", "ObjectiveValue", "ObjectiveUnit"]
        if key not in acceptable_keys:
            raise Exception(f"Cannot find key {key}, make sure the key exists in this list {acceptable_keys}")
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/ObjectivesAndTimeline/PrimaryObjective/Timeline/{segment_type}'
        self.__sendPatch(apiPath, payload={key: value})
        if self.get_specific_value_from_given_ramp_segment(segment_type, key) != value:
            raise Exception(f'An error has occured, setting {key} to {value} did not work!')
        return True

    def delete_added_application(self, app_id):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}'
        self.__sendDelete(apiPath, self.headers)

    def get_disk_usage_info(self):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/ExpectedDiskSpace'
        result = self.__sendGet(apiPath, 200)
        return result.json()

    def __set_traffic_profile(self, option):
        apiPath = f"/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1"
        self.__sendPatch(apiPath, payload={"Active": option})

    def __set_attack_profile(self, option):
        apiPath = f"/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1"
        self.__sendPatch(apiPath, payload={"Active": option})

    def enable_traffic_profile(self):
        self.__set_traffic_profile(True)

    def disable_traffic_profile(self):
        self.__set_traffic_profile(False)

    def enable_attack_profile(self):
        self.__set_attack_profile(True)

    def disable_attack_profile(self):
        self.__set_attack_profile(False)

    def enable_application_inherit_tls(self, app_id):
        """
        enable inherit tls for any added application
        """
        pass
        self.__set_application_inherit_tls_status(True, app_id)

    def disable_application_inherit_tls(self, app_id):
        """
        disable inherit tls for any added application

        :param app_id: application index in the added order
        """
        self.__set_application_inherit_tls_status(False, app_id)

    def enable_attack_inherit_tls(self, attack_id):
        """
        enable inherit tls for any added attack

        :param attack_id: attack index in the added order
        """
        self.__set_attack_inherit_tls_status(True, attack_id)

    def disable_attack_inherit_tls(self, attack_id):
        """
        enable inherit tls for any added attack

        :param attack_id: attack index in the added order
        """
        self.__set_attack_inherit_tls_status(False, attack_id)

    def __set_application_inherit_tls_status(self, status, app_id):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}'
        self.__sendPatch(apiPath, payload={"InheritTLS": status})

    def __set_attack_inherit_tls_status(self, status, attack_id):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack_id}'
        self.__sendPatch(apiPath, payload={"InheritTLS": status})

    def clear_agent_ownership(self, agents_ips=None):
        agents_ids = []
        result_id = self.get_current_session_result()
        if agents_ips:
            for agent_ip in agents_ips:
                agents_ids.append(self.get_agents_ids(agent_ip)[0])
        apiPath = "/api/v2/agents/operations/release"
        agents_to_release = []
        for agent_id in agents_ids:
            agents_to_release.append({"agentId": agent_id})
        payload = {
            "sessionId": result_id,
            "agentsData": agents_to_release
        }
        response = self.__sendPost(apiPath, payload=payload).json()
        status_url = response["id"]
        api_path = f'/api/v2/agents/operations/release/{status_url}'
        for index in range(10):
            response = self.__sendGet(api_path, 200).json()
            time.sleep(1)
            if response["state"] == "SUCCESS":
                return True
            else:
                continue

    def __get_results_list(self):
        apiPath = "/api/v2/results?exclude=links"
        result = self.__sendGet(apiPath, 200)
        return result.json()

    def get_current_session_result(self):
        sessions_results = self.__get_results_list()
        for index in range(0, len(sessions_results)):
            if sessions_results[index]['activeSession'] == self.sessionID:
                return sessions_results[index]['testName']
            else:
                continue

    def configure_attack_client_tls_settings(self, attack_id, config_endpoint, config_change):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack_id}/ClientTLSProfile'
        available_endpoints = ["tls12Enabled", "tls13Enabled", "ciphers12", "ciphers13", "immediateClose",
                               "middleBoxEnabled"]
        if config_endpoint not in available_endpoints:
            raise ("The endpoint you are trying to configure doesn't exist!")
        self.__sendPatch(apiPath, payload={config_endpoint: config_change})

    def configure_attack_server_tls_settings(self, attack_id, config_endpoint, config_change):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack_id}/ServerTLSProfile'
        available_endpoints = ["tls12Enabled", "tls13Enabled", "ciphers12", "ciphers13", "immediateClose",
                               "middleBoxEnabled"]
        if config_endpoint not in available_endpoints:
            raise ("The endpoint you are trying to configure doesn't exist!")
        self.__sendPatch(apiPath, payload={config_endpoint: config_change})

    def configure_application_client_tls_settings(self, app_id, config_endpoint, config_change):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}/ClientTLSProfile'
        available_endpoints = ["tls12Enabled", "tls13Enabled", "ciphers12", "ciphers13", "immediateClose",
                               "middleBoxEnabled"]
        if config_endpoint not in available_endpoints:
            raise ("The endpoint you are trying to configure doesn't exist!")
        self.__sendPatch(apiPath, payload={config_endpoint: config_change})

    def configure_application_server_tls_settings(self, app_id, config_endpoint, config_change):
        apiPath = f'/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{app_id}/ServerTLSProfile'
        available_endpoints = ["tls12Enabled", "tls13Enabled", "ciphers12", "ciphers13", "immediateClose",
                               "middleBoxEnabled"]
        if config_endpoint not in available_endpoints:
            raise ("The endpoint you are trying to configure doesn't exist!")
        self.__sendPatch(apiPath, payload={config_endpoint: config_change})

    def enable_configured_application(self, app_id):
        self.__set_configured_applications(True, app_id)

    def disable_configured_application(self, app_id):
        self.__set_configured_applications(False, app_id)

    def enable_configured_attack(self, app_id):
        self.__set_configured_attacks(True, app_id)

    def disable_configured_attack(self, attack_id):
        self.__set_configured_attacks(False, attack_id)

    def __set_configured_applications(self, option, application):
        apiPath = f"/api/v2/sessions/{self.sessionID}/config/config/TrafficProfiles/1/Applications/{application}"
        self.__sendPatch(apiPath, payload={"Active": option})

    def __set_configured_attacks(self, option, attack):
        apiPath = f"/api/v2/sessions/{self.sessionID}/config/config/AttackProfiles/1/Attacks/{attack}"
        self.__sendPatch(apiPath, payload={"Active": option})

    def set_sack(self, profile, tcp_profile, value=True):
        apiPath = '/api/v2/sessions/{}/config/config/{}/1/TrafficSettings/DefaultTransportProfile/{}'.format(
            self.sessionID, profile, tcp_profile)
        self.__sendPatch(apiPath, payload={"SackEnabled": value})

    def add_ipsec_stack(self, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks'.format(
            self.sessionID, network_segment_number)
        self.__sendPost(apiPath, {})

    def set_ipsec_stack_role(self, network_segment_number, ipstack_role):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/1'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"StackRole": ipstack_role})

    def set_ipsec_tunnel_reattempt_count(self, tunnel_reattempt_count, network_segment_number):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/1'.format(
            self.sessionID, network_segment_number)
        self.__sendPatch(apiPath, payload={"RetryCount": tunnel_reattempt_count})

    def set_ipsec_emulated_subnet_settings(self, startIP, increment, prefix=24, host_count_per_tunnel=1,
                                           network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/1/EmulatedSubConfig'.format(
            self.sessionID, network_segment_number)
        payload = {"Start": startIP,
                   "Increment": increment,
                   "Prefix": prefix,
                   "HostCountPerTunnel": host_count_per_tunnel}
        self.__sendPatch(apiPath, payload)

    def set_ph1_ipsec_algorithms(self, ph1_algorithms, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange/IKEPhase1Config'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        algorithms = list(ph1_algorithms.split(" "))
        payload = {"EncAlgorithm": algorithms[0],
                   "HashAlgorithm": algorithms[1],
                   "DHGroup": algorithms[2],
                   "PrfAlgorithm": algorithms[3]}
        self.__sendPatch(apiPath, payload)

    def set_ph2_ipsec_algorithms(self, ph2_algorithms, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange/IKEPhase2Config'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        algorithms = list(ph2_algorithms.split(" "))
        payload = {"EncAlgorithm": algorithms[0],
                   "HashAlgorithm": algorithms[1],
                   "PfsGroup": algorithms[2]}
        self.__sendPatch(apiPath, payload)

    def set_ipsec_public_peer(self, public_peer_ip, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"PublicPeer": public_peer_ip})

    def set_ipsec_public_peer_increment(self, public_peer_increment, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"PublicPeerIncrement": public_peer_increment})

    def set_ipsec_protected_subnet_start(self, protected_subnet_start, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange/ProtectedSubConfig'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"Start": protected_subnet_start})

    def set_ipsec_protected_subnet_increment(self, increment, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange/ProtectedSubConfig'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"Increment": increment})

    def set_ipsec_preshared_key(self, sharedkey, network_segment_number, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/IPSecRange/AuthSettings'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"SharedKey": sharedkey})

    def set_ipsec_outer_ip_range_start(self, outer_ip_range_start, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"IpStart": outer_ip_range_start})

    def set_ipsec_outer_ip_range_gateway(self, outer_ip_range_gateway, network_segment_number=1, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        self.__sendPatch(apiPath, {"GwStart": outer_ip_range_gateway})

    def set_ipsec_outer_ip_range_params(self, startIP, increment, count, maxcountperagent, netmask, gateway,
                                        network_segment_number, ipsec_stack_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment_number, ipsec_stack_number)
        payload = {"IpAuto": False,
                   "IpStart": startIP,
                   "IpIncr": increment,
                   "Count": count,
                   "maxCountPerAgent": maxcountperagent,
                   "NetMask": netmask,
                   "GwStart": gateway}
        self.__sendPatch(apiPath, payload)

    def check_ER_status(self, network_segment_number=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/EmulatedRouter'.format(
            self.sessionID, network_segment_number)
        response = self.__sendGet(apiPath, 200).json()
        return response['Enabled']

    def get_IP_stack_IP_start(self, network_segment_number=1, IP_range=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPRanges/{}'.format(
            self.sessionID, network_segment_number, IP_range)
        response = self.__sendGet(apiPath, 200).json()
        return response['IpStart']

    def get_TLS_VPN_IP_start(self, network_segment_number=1, tunnel_stack=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/TunnelStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment_number, tunnel_stack)
        response = self.__sendGet(apiPath, 200).json()
        return response['IpStart']

    def get_IPsec_IP_start(self, network_segment_number=1, IPsec_stack=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/IPNetworkSegment/{}/IPSecStacks/{}/OuterIPRange'.format(
            self.sessionID, network_segment_number, IPsec_stack)
        response = self.__sendGet(apiPath, 200).json()
        return response['IpStart']

    def create_session_precanned_config(self, config_name):
        config_lookup = {config["displayName"]: config["id"] for config in self.get_all_configs()}
        config_id = config_lookup.get(config_name)
        if config_id is None:
            raise ValueError(f"Pre-canned config with name '{config_name}' was not found")
        self.configID = config_id
        self.sessionID = self.open_config()

    def set_base_path_url(self, server_test_ip):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/1/PepDUT/AuthProfileParams/3'.format(
            self.sessionID)
        concated_ip = "/http/" + server_test_ip
        self.__sendPatch(apiPath, payload={"Value": concated_ip})

    def set_okta_credentials_ep(self, okta_username, okta_password):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/1/PepDUT/AuthProfileParams/4'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"Value": okta_username})
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/1/PepDUT/AuthProfileParams/5'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"Value": okta_password})

    def set_okta_credentials_gp(self, okta_username, okta_password):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/1/PepDUT/AuthProfileParams/1'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"Value": okta_username})
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/1/PepDUT/AuthProfileParams/2'.format(
            self.sessionID)
        self.__sendPatch(apiPath, payload={"Value": okta_password})

    def set_dut_name(self, name, dut_segment=1):
        apiPath = '/api/v2/sessions/{}/config/config/NetworkProfiles/1/DUTNetworkSegment/{}'.format(self.sessionID, dut_segment)
        self.__sendPatch(apiPath, payload={"Name":name})
    
    def export_controller(self, export_path=None, file_name="mycontroller.zip"):
        apiPath = '/api/v2/controller-migration/operations/export'
        payload = {
            "keycloak": True,
            "config": True,
            "licenseServers": True,
            "externalNatsBrokers": True,
            "results": True
        }
        result = self.__sendPost(apiPath, payload=payload).json()
        apiPath = apiPath + "/" + str(result["id"])
        for index in range(36):
            time.sleep(10)
            result = self.__sendGet(apiPath, 200).json()
            if result["state"] == "SUCCESS":
                download_url = result["resultUrl"]
                break
            elif result["state"] == "FAILURE":
                raise "Export controller operation did not succeeded after 5 minutes"
        customHeaders = self.headers
        customHeaders['Accept'] = 'application/zip'
        response = self.session.get('{}{}'.format(self.host, "/" + download_url), headers=customHeaders, stream=True)
        if export_path:
            file_name = os.path.join(export_path, file_name)
        with open(file_name, 'wb') as fd:
            for chunk in response.iter_content(chunk_size=256):
                fd.write(chunk)

    def import_controller(self, import_path=None, file_name="fakenews.zip"):
        apiPath = '/api/v2/controller-migration/operations/import'
        customHeaders = self.headers
        customHeaders['Accept'] = 'application/json'
        if import_path:
            file_to_open = import_path + file_name
        else:
            file_to_open = file_name
        mp_encoder = MultipartEncoder(
            fields={
                "request": json.dumps(
                    {
                        "keycloak": True,
                        "config": True,
                        "licenseServers": True,
                        "externalNatsBrokers": True,
                        "results": True
                    }
                ),
                "file": (file_name, open(file_to_open, "rb"), 'application/zip')
            }
        )

        customHeaders['content-type'] = mp_encoder.content_type
        result = self.__sendPost(apiPath, payload=mp_encoder, customHeaders=self.headers).json()
        print(f"This is post {result}")

        apiPath = apiPath + "/" + str(result["id"])
        for index in range(360):
            time.sleep(3)
            result = self.__sendGet(apiPath, 200).json()
            if result["state"] == "SUCCESS":
                self.session.close()
            elif result["state"] == "ERROR":
                self.session.close()
                raise "Import was not succesful"
    def get_results_test_ids(self):
        all_results = self.__sendGet('/api/v2/results', 200).json()
        return [result["id"] for result in all_results]
    
    def get_test_display_name(self, test_id):
        all_results = self.__sendGet('/api/v2/results', 200).json()
        for result in all_results:
            if result["id"] == test_id:
                return result["displayName"]
    
    def delete_all_browse_results(self, delete_all_active_session=False, timeout=60):
        apiPath = "/api/v2/results/operations/batch-delete"
        if delete_all_active_session:
            active_sessions = self.__sendGet('/api/v2/sessions', 200).json()
            active_sessions_ids = [session["id"] for session in active_sessions]
            for session in active_sessions_ids:
                self.__sendDelete(f"/api/v2/sessions/{session}", self.headers)
                
        tests_ids = self.get_results_test_ids()
        payload = [{"id": f"{test_id}"} for test_id in tests_ids]
        operation_id = self.sendPost(apiPath, payload).json()["id"]

        end_time = time.time() + timeout
        while time.time() < end_time:
            if self.sendGet(apiPath+f"/{operation_id}", 200).json()["state"] == "SUCCESS":
                return True
            time.sleep(1)
        raise Exception("Failed to delete all results from Controller")

    def save_csv_result(self, test_id, csvLocation, exportTimeout=180):
        apiPath = f"/api/v2/results/{test_id}/operations/generate-csv"
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
