from platform import platform
from pathlib import Path
import sys
import os
import subprocess


def setup():
    run(
        [
            py() + " -m pip install -r requirements.txt",
        ]
    )


def py():
    """
    Returns path to python executable to be used.
    """
    BASE_DIR = BASE_DIR = Path(__file__).resolve().parent
    py.path = os.path.join(
        os.path.join(BASE_DIR.parent),
        ".env",
        "bin",
        "python.exe" if "win" in sys.platform else "python"
    )
    if not os.path.exists(py.path):
        py.path = sys.executable

    # since some paths may contain spaces
    py.path = '"' + py.path + '"'
    print(py.path)
    return py.path


def flush_output(fd, filename):
    """
    Flush the log file and print to console
    """
    if fd is None:
        return
    fd.flush()
    fd.seek(0)
    ret = fd.read()
    print(ret)
    fd.close()
    os.remove(filename)
    return ret


def run(commands, capture_output=False):
    """
    Executes a list of commands in a native shell and raises exception upon
    failure.
    """
    fd = None
    logfile = "log.txt"
    if capture_output:
        fd = open(logfile, "w+")
    try:
        for cmd in commands:
            print(">>>> " + cmd + " <<<<")
            if sys.platform != "win32":
                cmd = cmd.encode("utf-8", errors="ignore")
            subprocess.check_call(cmd, shell=True, stdout=fd)
        return flush_output(fd, logfile)
    except Exception:
        flush_output(fd, logfile)
        sys.exit(1)

def main():
    if len(sys.argv) >= 2:
        globals()[sys.argv[1]](*sys.argv[2:])
    else:
        print("usage: python do.py [args]")


if __name__ == "__main__":
    main()