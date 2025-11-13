import sys
import argparse
sys.path.append("..")
from RESTasV3 import RESTasV3

# CyPerf API sample script to create multiple users for the Controller

def parse_pair(pair):
    """Parse and validate a user:password pair."""
    if ':' not in pair:
        raise argparse.ArgumentTypeError("Invalid format, expected user:password")
    user, pwd = pair.split(':', 1)
    if not user or not pwd:
        raise argparse.ArgumentTypeError(f"Empty user or password in: {pair}")
    return user, pwd

def create_user_on_server(rest, user, password):
    """Create a user on the CyPerf Controller."""
    print(f"Creating user={user} with password length={len(password)}")

    rest.add_new_user(
        username=user,
        email=f"{user}@company.com",
        firstName=user,
        lastName="N/A"
    )
    rest.change_user_role(user, "cyperf-user")
    rest.change_user_password(user, password)  # Password must include a special character

def main():
    parser = argparse.ArgumentParser(
        description="Create multiple users on a CyPerf Controller. "
                    "Example: script.py 10.38.69.103 alice:CyPerf#1 bob:CyPerf#2"
    )
    parser.add_argument('controller_ip', help="Controller IP address (e.g., 10.38.69.103)")
    parser.add_argument('pairs', nargs='+', type=parse_pair,
                        help='User:password pairs, e.g., alice:CyPerf#1 bob:CyPerf#2')

    args = parser.parse_args()

    # Initialize REST API for the specified controller
    rest = RESTasV3(args.controller_ip)

    for user, pwd in args.pairs:
        create_user_on_server(rest, user, pwd)

if __name__ == "__main__":
    main()
