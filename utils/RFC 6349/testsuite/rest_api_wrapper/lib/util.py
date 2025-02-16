#!/usr/bin/env python
import re
import sys
import time
import subprocess
import argparse
import socket
import telnetlib
#from paramiko.util import log_to_file
import logging
import pytest
import re, os
import datetime
import pandas as pd
from copy import deepcopy
#libpath = os.path.abspath(__file__+"/../../testsuite")
#sys.path.insert(0,libpath)
#from ixload import IxLoad
from tabulate import tabulate
#version 1.0
def result_log(ret_name=0):
    path = os.path.abspath(__file__+"/../../../../")
    os.chdir(path)
    datestring = datetime.datetime.now().strftime("%Y_%m_%d_%H_%M_%S")
    name = "Result"+str(datestring)
    os.mkdir(name)
    if ret_name:
        return name
    return name


def parse_status(result):
    #[{"status": 0, "log": err}, {"status": 1}]
    for r in result:
        if (r["status"]==0):
            return ({"fail":r['log']})
    return ({"pass":"success"})

def pytest_assert(logger, condition, message = None):
    __tracebackhide__ = True
    if not condition:
        set_logger(logger, level="ERROR", message=message)
        pytest.fail(message)
    else:
        set_logger(logger, level="INFO", message="Test Passed")

def consolidate_output(logger, input):
    new_dict = {}
    for key in input.keys():
        for k, v in input[key].items():
            new_dict[key] = (k, v)
    headers = ["Type", "Buffer", "Average"]
    #print(tabulate([(k,) + v for k, v in new_dict.items()], headers=headers))
    set_logger(logger, level="INFO", message="\n" + str(tabulate([(k,) + v for k, v in new_dict.items()], headers=headers)))


def consolidate_result(logger, input):
    pd.set_option('display.max_rows', 500)
    pd.set_option('display.max_columns', 500)
    column_name = 'buffer_size' + '     |' + '   average (Mbps)'
    input_dict = {"buffer_size" : [], "average": []}
    for column, values in input.items():
        row_value = []
        for buffer_size, avg_value in values.items():
            input_dict["buffer_size"].append(str(buffer_size))
            input_dict["average"].append(str(avg_value))
    df = pd.DataFrame(input_dict, index = list(input.keys()))
    print(df)
    set_logger(logger, level="INFO", message= df)


def set_logger(
    logger,
    log_format='%(asctime)-8s %(levelname)-8s %(message)s\n',
    log_name='',
    level = 'INFO',
    message = '',
    ):
    log_file = logger
    log = logging.getLogger(log_name)
    log_formatter = logging.Formatter(log_format)
    if log_file:
        file_handler_info = logging.FileHandler(log_file)
    else:
        file_handler_info = logging.FileHandler(log)
    file_handler_info.setFormatter(log_formatter)

    log_level = getattr(logging, level)
    log.addHandler(file_handler_info)

    log.setLevel(log_level)
    log.log(log.getEffectiveLevel(), message)

    log.handlers = []

    file_handler_info.flush()

def logger_msg(logger, msg, level='INFO'):
    set_logger(logger, level=level, message=msg)


def maxtput(tputDict):
    max = 0
    tput = {}
    for key, value in tputDict.items():
        for key2 in value.keys():
            if int(key2) > int(max):
                max = key2
                tput = {key: {key2: value[key2]}}
    return (tput)
    
def average(lst):
    sum_num = 0
    for t in lst:
        sum_num = sum_num + int(t)
    return sum_num / len(lst)

# def ping_works(logger, payload_size, args):
#     # we capture the output to prevent ping
#     # from printing to terminal
#     tn = telnetlib.Telnet(args['host'], 8021)
#     tn.read_until(b"login: ")
#     tn.write(bytes(args['port'], 'ascii') + b"\r\n")
#     ping_data = "ping" + " " + str(args['target']) + " " + "-I ixint1 -c 1 -s" + " " + str(payload_size) + " " + "-M do"
#     #sys.stdout.write('%s: ' % ping_data)
#     if b'#' in tn.read_until(b'#', timeout=5):
#         tn.write(bytes(ping_data, 'ascii') + b"\r\n")
#         if b'ttl' in tn.read_until(b'ttl', timeout=5):
#             sys.stdout.write('%s: ' % "success")
#             sys.stdout.write('%s: ' % tn.read_until(b'ttl', timeout=5))
#             return True
#         else:
#             sys.stdout.write('%s: '% tn.read_until(b'PING', timeout=5))
#             return False

# def telnet(logger, host, port, ip, obj):
#     lo = 0  # MTUs lower or equal do work
#     hi = 9000  # MTUs greater or equal don't work
#     #print('>>> PMTU to %s in range [%d, %d)' % (args.target, lo, hi))
#     arg = {'host':host, 'port': port, 'target': ip, 'lo':0, 'hi': 9000}
#     while lo + 1 < hi:
#         mid = (lo + hi) // 2

#         sys.stdout.write('%d: ' % mid)
#         sys.stdout.flush()
#         for i in range(2):
#             if ping_works(logger, mid, arg):
#                 import pdb;pdb.set_trace()
#                 lo = mid
#                 break
#             else:
#                 import pdb;pdb.set_trace()
#                 sys.stdout.write('* ')
#                 sys.stdout.flush()
#                 time.sleep(0.2)
#         else:
#             import pdb;pdb.set_trace()
#             hi = mid
#             print('')

#     # header_size = 28 if args.ipv4 else 48
#     header_size = 28
#     print('>>> optimal MTU to %s: %d  = %d' % (
#         arg['target'], lo,  lo
#     ))
#     return (lo)