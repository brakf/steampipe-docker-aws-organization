# steampipe-docker-aws-cross-organization
Dockerfile for Steampipe that automatically generates the AWS and Steampipe config for cross-organization queries

# Steampipe AWS Organizations Docker Container

This repository contains a Dockerfile and accompanying scripts to set up a Docker container for querying AWS Organizations using [Steampipe](https://steampipe.io/). This setup is particularly useful for auditing AWS accounts across an organization using cross-account roles.
It automatically generates the needed aws cli profiles and steampipe connections using the [generate_config_for_cross_account_roles](https://steampipe.io/docs/guides/aws-orgs) script.
Check out the respective documentation regarding the required permissions. Those permissions need to be set on the container, either by providing a Task Role to an ECS container or by mounting your ~/.aws/credentials file to the container when running it locally.


## Usage

### Build the Docker Image

To build the Docker image, run the following command in the directory containing the Dockerfile:

```bash
docker build -t steampipe-aws-org .
```

### Run the Container in Server Mode

To run the container, use the following command. It starts the container and exposes an SQL interface. The username is steampipe, the password can be specified via parameter.

```bash
docker run  -d -p 9193:9193 \
            --env ENVIRONMENT_TYPE=LOCAL \  
            --env AUDIT_ROLE=audit-readonly \  
            --env SOURCE_PROFILE=default \
            --env STEAMPIPE_PASSWORD=supersecret \
            --env ENABLED_REGIONS='us-east-1,eu-central-1,ap-southeast-1' \
            --env MODE=SERVER  \
            -v $HOME/.aws/credentials:/home/steampipe/.aws/credentials:ro \
            steampipe-aws-org:latest
```

### Run the Container in Interactive Mode
Interactive mode only works locally and opens the interactive steampipe CLI with auto-completion.

```bash
docker run -it --rm \
  --env ENVIRONMENT_TYPE=LOCAL \
  --env AUDIT_ROLE=audit-readonly \
  --env SOURCE_PROFILE=default \
  --env MODE=INTERACTIVE  \
  --env ENABLED_REGIONS='us-east-1,eu-central-1,ap-southeast-1' \
  -v $HOME/.aws/credentials:/home/steampipe/.aws/credentials:ro \
  steampipe-aws-org:latest \
  steampipe query
```


### Environment Variables:**

- `ENVIRONMENT_TYPE`: Set this to `LOCAL` for local configurations, `IMDS` for EC2 or `ECS`
- `AUDIT_ROLE`: The name of the audit role in AWS.
- `STEAMPIPE_PASSWORD`: The password for the Steampipe database (only used for `SERVER` mode).
- `SOURCE_PROFILE`: The AWS CLI profile to use (only required if `ENVIRONMENT_TYPE` is `LOCAL`).
- `MODE`: `SERVER` or `INTERACTIVE` mode
- `ENABLED_REGIONS`: Specified the AWS regions that should be included. `*` for all regions.