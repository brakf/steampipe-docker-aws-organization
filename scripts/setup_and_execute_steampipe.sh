#!/bin/bash
set -e

# Read the input parameters
ENVIRONMENT_TYPE=$1
AUDIT_ROLE=$2
STEAMPIPE_PASSWORD=$3
SOURCE_PROFLE=$4 #only needed if ENVIRONMENT_TYPE=LOCAL
ENABLED_REGIONS=$5
MODE=$6


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
rm -f ~/.steampipe/config/aws.spc
rm -f ~/.aws/config


echo "ENVIRONMENT_TYPE: $ENVIRONMENT_TYPE"
if [ "$ENVIRONMENT_TYPE" = "LOCAL" ]; then
    echo "SOURCE_PROFILE: $SOURCE_PROFILE"
    ./generate_config_for_cross_account_roles.sh LOCAL $AUDIT_ROLE ~/.aws/config $SOURCE_PROFLE $ENABLED_REGIONS 

else
    ./generate_config_for_cross_account_roles.sh $ENVIRONMENT_TYPE $AUDIT_ROLE ~/.aws/config "" $ENABLED_REGIONS
fi


echo "Number of created AWS Profiles:"
grep -c '^\[profile' ~/.aws/config

echo "Number of created Steampipe Connections (incl. 1 aggregate connection ):"
grep -c '^connection' ~/.steampipe/config/aws.spc

if [ "$MODE" = "INTERACTIVE" ]; then
    steampipe query
elif [ "$MODE" = "SERVER" ]; then
    steampipe service start --foreground --database-password $STEAMPIPE_PASSWORD 
else 
    echo "Invalid mode: $MODE"
    exit 1
fi
