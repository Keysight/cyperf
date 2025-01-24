import re, logging
import pytest
import json
import os

def pytest_exception_interact(node, call, report):
    # end all pytests on first exception that is encountered
    pytest.exit(call.excinfo.traceback[0])

def pytest_addoption(parser):
    # called before running tests to register command line options for pytest
    parser.addoption("--logstatus", action="store", default=None)
    parser.addoption("--paramlist", action="store", default=None)
    parser.addoption("--log", action="store", default='final_result.log')

@pytest.fixture(scope='session')
def logger(request):
    log_file = request.config.getvalue("--logstatus")
    if log_file is None:
        raise Exception("logstatus is a mandatory command line")
    logging
    log = open(log_file, 'w+')
    return log_file

@pytest.fixture(scope='session')
def logger_report(request):
    final_log = request.config.getvalue("--log")
    logging
    log1 = open(final_log, 'w+')
    return final_log
