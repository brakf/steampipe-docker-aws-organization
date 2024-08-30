#!/usr/bin/env python3

import sys
import os

def remove_profile_block(file_path, account_id):
    # Read the content of the file
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Variables to store profile name and block indices
    profile_name = None
    start_index = None
    end_index = None

    # Iterate through the lines to find the block containing the account ID
    for i, line in enumerate(lines):
        if line.strip().startswith('[profile '):
            # Start of a profile block
            start_index = i
            profile_name = line.strip().split()[1].strip(']')
        if f"arn:aws:iam::{account_id}" in line:
            # Found the account ID within the current block
            # Identify the end of the block (next block start or end of file)
            for j in range(i, len(lines)):
                if lines[j].strip().startswith('[profile ') and j != start_index:
                    end_index = j
                    break
            if end_index is None:
                end_index = len(lines)  # If it's the last block in the file
            break

    # If profile block is found, remove it from the lines
    if start_index is not None and end_index is not None:
        del lines[start_index:end_index]

        # Write the modified content back to the file
        with open(file_path, 'w') as file:
            file.writelines(lines)

        return profile_name
    else:
        return None

def remove_connection_block(file_path, profile_name):
    # Read the content of the file
    with open(file_path, 'r') as file:
        lines = file.readlines()

    # Variables to store block indices
    start_index = None
    end_index = None

    # Iterate through the lines to find the block containing the profile name
    for i, line in enumerate(lines):
        if line.strip().startswith('connection '):
            # Start of a connection block
            start_index = i
        if f'profile = "{profile_name}"' in line:
            # Found the profile within the current block
            # Identify the end of the block (next block start or end of file)
            for j in range(i, len(lines)):
                if lines[j].strip().startswith('connection ') and j != start_index:
                    end_index = j
                    break
            if end_index is None:
                end_index = len(lines)  # If it's the last block in the file
            break

    # If connection block is found, remove it from the lines
    if start_index is not None and end_index is not None:
        del lines[start_index:end_index]

        # Write the modified content back to the file
        with open(file_path, 'w') as file:
            file.writelines(lines)

        print(f"Connection block with profile '{profile_name}' has been removed from the file.")
    else:
        print(f"No connection block found for profile '{profile_name}'.")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: ./script_name.py <aws_config_file_path> <connections_file_path> <account_id>")
        sys.exit(1)

    aws_config_file_path = sys.argv[1]
    connections_file_path = sys.argv[2]
    account_id = sys.argv[3]

    # Remove profile block from AWS config file
    profile_name = remove_profile_block(aws_config_file_path, account_id)

    if profile_name:
        print(f"Profile block '{profile_name}' has been removed from the AWS config file.")
        # Remove connection block from connections file
        remove_connection_block(connections_file_path, profile_name)
    else:
        print(f"No profile block found for account ID {account_id}.")