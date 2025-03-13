import logging
import pprint
# Create a logger for selective logging
#Create a logger for selective logging
selective_logger = logging.getLogger('selective')
selective_logger.setLevel(logging.INFO)
selective_logger.propagate = False
# Remove any existing handlers
selective_logger.handlers.clear()

selective_logger1 = logging.getLogger('selective1')
selective_logger1.setLevel(logging.INFO)
selective_logger1.propagate = False
# Remove any existing handlers
selective_logger1.handlers.clear()

selective_logger2 = logging.getLogger('selective2')
selective_logger2.setLevel(logging.INFO)
selective_logger2.propagate = False
# Remove any existing handlers
selective_logger2.handlers.clear()

# Create a file handler for the selective logger
selective_handler = logging.FileHandler('selective_report_.log')
selective_handler.setLevel(logging.INFO)

# Create a formatter and set it for the selective handler
selective_formatter = logging.Formatter('%(message)s')
selective_handler.setFormatter(selective_formatter)

# Add the selective handler to the selective logger
selective_logger.addHandler(selective_handler)
selective_logger1.addHandler(selective_handler)
selective_logger2.addHandler(selective_handler)

# Define a function to print to the selective logger
def print_selective(message, *args, width=120):
    formatted_message = f"{message.format(*args):<{width}}"
    selective_logger.info(formatted_message)


def print_selective1(message, *args, width=120):
    formatted_message = f"{message.format(*args):<{width}}"
    selective_logger1.info(formatted_message)

def print_dictionary(dictionary):
    # Pretty-print the dictionary
    pretty_dict = pprint.pformat(dictionary)

    # Log the formatted dictionary
    #logger.info("Dictionary:")
    for line in pretty_dict.splitlines():
        selective_logger2.info(line)
