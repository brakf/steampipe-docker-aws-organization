FROM ghcr.io/turbot/steampipe:latest

ARG TARGETPLATFORM

USER root:0
RUN apt-get update -y \
    && apt-get install -y git wget curl unzip && apt-get install python3 -y

RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then ARCHITECTURE=amd64; elif [ "$TARGETPLATFORM" = "linux/arm/v7" ]; then ARCHITECTURE=arm; elif [ "$TARGETPLATFORM" = "linux/arm64" ]; then ARCHITECTURE=aarch64; else ARCHITECTURE=amd64; fi && \
    if [ "$ARCHITECTURE" = "amd64" ]; then curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"; else curl "https://awscli.amazonaws.com/awscli-exe-linux-aarch64.zip" -o "awscliv2.zip"; fi && \
    unzip -qq awscliv2.zip && \
    ./aws/install && \
    /usr/local/bin/aws --version

WORKDIR /workspace
USER steampipe:0

RUN steampipe plugin install steampipe aws

# RUN curl -o ./generate_config_for_cross_account_roles.sh https://raw.githubusercontent.com/turbot/steampipe-samples/main/all/aws-organizations-scripts/generate_config_for_cross_account_roles.sh
#using my own fork of the script until the PR is merged: https://github.com/turbot/steampipe-samples/pull/27
RUN curl -o ./generate_config_for_cross_account_roles.sh https://raw.githubusercontent.com/brakf/steampipe-samples/main/all/aws-organizations-scripts/generate_config_for_cross_account_roles.sh 
RUN chmod +x ./generate_config_for_cross_account_roles.sh

COPY --chown=steampipe scripts/exclude_accounts.py . 
RUN chmod +x ./exclude_accounts.py

COPY --chown=steampipe scripts/setup_and_execute_steampipe.sh . 
RUN chmod +x ./setup_and_execute_steampipe.sh

ENV ENVIRONMENT_TYPE=LOCAL
ENV AUDIT_ROLE=steampipe-readonly
ENV SOURCE_PROFILE=default
ENV STEAMPIPE_PASSWORD=secretpassword
ENV ENABLED_REGIONS=*
ENV MODE=SERVER
ENV EXCLUDED_ACCOUNTS=

RUN mkdir -p /home/steampipe/.aws

ENTRYPOINT ["/bin/sh", "-c", "./setup_and_execute_steampipe.sh $ENVIRONMENT_TYPE $AUDIT_ROLE $STEAMPIPE_PASSWORD $SOURCE_PROFILE $ENABLED_REGIONS $MODE $EXCLUDED_ACCOUNTS"]