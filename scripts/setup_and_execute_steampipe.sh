#!/bin/bash
set -e

# Read the input parameters
ENVIRONMENT_TYPE=$1
AUDIT_ROLE=$2
STEAMPIPE_PASSWORD=$3
SOURCE_PROFLE=$4 #only needed if ENVIRONMENT_TYPE=LOCAL
ENABLED_REGIONS=$5
MODE=$6
EXCLUDED_ACCOUNTS=$7 #list of accounts ids to exclude from the configuration

AWS_CONFIG_FILE_PATH=~/.aws/config  # Update with your AWS config file path
STEAMPIPE_CONFIG_PATH=~/.steampipe/config/aws.spc


if [ -z "$ENABLED_REGIONS" ] || [ "$ENABLED_REGIONS" = "*" ]; then
    ENABLED_REGIONS="[\"*\"]"
else
    # Convert ENABLED REGIONS (input format: region1,region2; output format: ["region1","region2"])
    IFS=',' read -r -a regions <<< "$ENABLED_REGIONS"
    ENABLED_REGIONS="["
    for region in "${regions[@]}"
    do
        ENABLED_REGIONS="$ENABLED_REGIONS\"$region\","
    done
    ENABLED_REGIONS="${ENABLED_REGIONS::-1}]"
fi


#cleanup old configuration
rm -f $STEAMPIPE_CONFIG_PATH
rm -f $AWS_CONFIG_FILE_PATH


echo "ENVIRONMENT_TYPE: $ENVIRONMENT_TYPE"
if [ "$ENVIRONMENT_TYPE" = "LOCAL" ]; then
    echo "SOURCE_PROFILE: $SOURCE_PROFILE"
    ./generate_config_for_cross_account_roles.sh LOCAL $AUDIT_ROLE $AWS_CONFIG_FILE_PATH $SOURCE_PROFLE $ENABLED_REGIONS 

else
    ./generate_config_for_cross_account_roles.sh $ENVIRONMENT_TYPE $AUDIT_ROLE $AWS_CONFIG_FILE_PATH "" $ENABLED_REGIONS
fi

# Exclude accounts if needed
if [ ! -z "$EXCLUDED_ACCOUNTS" ]; then
    # Convert the comma-separated list into an array
    IFS=',' read -ra ACCOUNTS <<< "$EXCLUDED_ACCOUNTS"
    
    for ACCOUNT_ID in "${ACCOUNTS[@]}"; do
        echo "Excluding account $ACCOUNT_ID"
        
        # Call the Python script to remove the profile and connection blocks
        ./exclude_accounts.py "$AWS_CONFIG_FILE_PATH" "$STEAMPIPE_CONFIG_PATH" "$ACCOUNT_ID"
        
        # Check the exit status of the Python script
        if [ $? -ne 0 ]; then
            echo "Failed to exclude account $ACCOUNT_ID"
            exit 1
        fi
    done
fi


echo "Number of created AWS Profiles:"
grep -c '^\[profile' $AWS_CONFIG_FILE_PATH

echo "Number of created Steampipe Connections (incl. 1 aggregate connection ):"
grep -c '^connection' $STEAMPIPE_CONFIG_PATH

#Run test query to generate auto-completion 
steampipe query "select count(*) as \"Accounts\" from aws_account;"

if [ "$MODE" = "INTERACTIVE" ]; then
    steampipe query
elif [ "$MODE" = "SERVER" ]; then
    steampipe service start --foreground --database-password $STEAMPIPE_PASSWORD 
else 
    echo "Invalid mode: $MODE"
    exit 1
fi
