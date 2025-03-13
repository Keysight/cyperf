import json
import os

import pandas as pd
from tabulate import tabulate


class JSONObject:
    def __init__(self, dict):
        vars(self).update(dict)


def json_to_class(path):
    """
    Converts a json into a class
    """
    json_file = open(path)
    s = json_file.read()
    return json.loads(s, object_hook=JSONObject)


class Statistics:
    criteria_message = ''

    def __init__(self, csvs_path):
        """
        Takes in the path to csv folder
        """
        self.csvs_path = csvs_path
        self.headers = ['Condition', 'Status']
        self.table = []
        self.stats_failures = []
        self.config_type = None
        self.stats = {}
        self.include_baseline_file = True
        for csv in os.listdir(csvs_path):
            if csv.endswith(".csv"):
                self.stats[csv[:-4]] = self.make_dataframe(os.path.join(csvs_path, csv))

    def make_dataframe(self, csv_file_path):
        '''
        Creates a data frame from a csv found at that path
        :csv_file_path
        '''
        with open(csv_file_path, encoding='utf-8') as csvf:
            try:
                csv = pd.read_csv(csvf)
            except pd.errors.EmptyDataError:
                raise Exception("{} is empty".format(csv_file_path))
            except pd.errors.ParserError:
                raise Exception("{} is corupt".format(csv_file_path))
        return csv 

    @staticmethod
    def last(df):
        df = df[df['Timestamp epoch ms'] == max(df['Timestamp epoch ms'])]#returns a data frame not a pandas series
        return df

    def preform_validation(self, validation_entry):
        stats = self.stats
        last = Statistics.last ## kind of function pointer 
        try:
            validation_ok = eval(validation_entry.condition)
        except :
            raise Exception("This validation is not written correctly: {}".format(validation_entry.condition))
        if validation_ok:
            self.table.append([validation_entry.description, 'Pass'])
        else:
            self.table.append([validation_entry.description, 'Fail'])
            self.stats_failures.append(validation_entry.description)

    def validate_criteria_file(self, criteria_path):
        """
        Preforms specific validation for a config and decides if the baseline validation needs to be added
        criteria path: path to the json criteria
        """
        validator = json_to_class(criteria_path)
        self.include_baseline_file = validator.include_baseline
        if self.config_type['dut']:
            validator = validator.DUT
        else:
            validator = validator.B2B
        for validation_entry in validator:
            self.preform_validation(validation_entry)

    def validate_baseline_file(self, criteria_path):
        """
        Checks what type of profiles are present in the test and preforms general validation
        criteria path: path to the json criteria
        config_type: A dictionary that flags the types of profiles present inside the test
        """
        validator = json_to_class(criteria_path)
        if self.config_type['dut']:
            validator = validator.DUT
        else:
            validator = validator.B2B
        if self.config_type['traffic'] or self.config_type['attack']:
            for validation_entry in validator.general:
                self.preform_validation(validation_entry)
        else:
            raise Exception('The config does not have an attack or traffic profile')
        if self.config_type['traffic']:
            for validation_entry in validator.traffic:
                self.preform_validation(validation_entry)
        if self.config_type['attack']:
            for validation_entry in validator.attack:
                self.preform_validation(validation_entry)

    def validate_mdw_stats(self, config_type, config_path=""):
        """
        Using a the criteria json and the baseline json, validates the resources returned after the run.
        config_type: A dictionary that flags the types of profiles present inside the test
        config_name: same name as the test that ran.
        """
        self.config_type = config_type
        if os.path.exists(config_path):
            config_name = os.path.basename(config_path)
            print("Config: {}\n\n".format(config_name))
            criteria_path = os.path.join(config_path, 'validation.json')
            #print(criteria_path)
            print(f'********Applying packet loss Validation present in the configuration file @ {criteria_path} *******************'.ljust(100))
            print("**************************************************************************************".ljust(100))
            print(f'*********Running packet loss Validation for {config_name}******************************************'.ljust(100))

            if os.path.exists(criteria_path):

                try:
                    self.validate_criteria_file(criteria_path)
                except AttributeError as e:
                    print('Criteria {} could not be applied due to: {}'.format(config_name, e))
            else:
                self.include_baseline_file = True
        if self.include_baseline_file:
            criteria_path = os.path.join("../resources", "baseline_validation.json")
            self.validate_baseline_file(criteria_path)
        else:
            print('****************Baseline validation skipped********************************************')
        print(tabulate(self.table, self.headers, tablefmt="grid"))
        return "; ".join(self.stats_failures)

