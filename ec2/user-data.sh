#!/bin/bash

# Configure hostname for datadog-agent
HOST_NAME=$(aws ec2 describe-instances --region us-east-1 --filters "Name=private-dns-name,Values=$(hostname)" --query 'Reservations[*].Instances[*].{Name:Tags[?Key==`Name`]|[0].Value}' --output text)
sudo sed -i "s/# hostname: <HOSTNAME_NAME>/hostname: $HOST_NAME/" /etc/datadog-agent/datadog.yaml
sleep 2


# Jenkins details
SECRET_JSON=$(aws secretsmanager get-secret-value --secret-id ${JENKINS_SECRET} --region us-east-1 --query 'SecretString' --output text)
JENKINS_URL=$(echo $SECRET_JSON | jq -r '.JENKINS_URL')
JOB_NAME=$(echo $SECRET_JSON | jq -r '.JOB_NAME')
USER_ID=$(echo $SECRET_JSON | jq -r '.JENKINS_USER_ID')
API_TOKEN=$(echo $SECRET_JSON | jq -r '.JENKINS_API_TOKEN')

# Parameters to send to the job
# HOST_IP=$(aws ec2 describe-instances --region us-east-1 --filters "Name=private-dns-name,Values=$(hostname)" --query 'Reservations[*].Instances[*].{PrivateIpAddress:PrivateIpAddress}' --output text)

TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
HOST_IP=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" "http://169.254.169.254/latest/meta-data/local-ipv4")

ENV_NAME=${ENV_NAME}
DOMAIN_NAME=${DOMAIN_NAME}

# Deploy ec2 with nginx config
curl -X POST "$JENKINS_URL/job/$JOB_NAME/buildWithParameters?HOST_IP=$HOST_IP&ENV_NAME=$ENV_NAME&APPTYPE=app-a&BRANCH=${BRANCH}" --user $USER_ID:$API_TOKEN


# Deploy APP-B
sleep 10
curl -X POST "$JENKINS_URL/job/$JOB_NAME/buildWithParameters?HOST_IP=$HOST_IP&APPTYPE=app-b&BRANCH=master" --user $USER_ID:$API_TOKEN


# Restart the datadog-agent
sudo service datadog-agent restart

sleep 300
# Install and Configure twistlock agent
export ACCESS_KEY=$(aws --region us-east-1 ssm get-parameters --names accesskeyid --with-decryption --query Parameters[].Value --output text)
export SECRET_KEY=$(aws --region us-east-1 ssm get-parameters --names secretkey --with-decryption --query Parameters[].Value --output text)
export TOKEN=$(curl -k -H "Content-Type: application/json" -X POST -d "{\"username\": \"$ACCESS_KEY\", \"password\": \"$SECRET_KEY\"}" https://us-west1.cloud.twistlock.com/<id>/api/v1/authenticate | jq -r .token)
curl -sSL -k --header "authorization: Bearer $TOKEN" -X POST https://us-west1.cloud.twistlock.com/<id>/api/v1/scripts/defender.sh | sudo bash -s -- -c "us-west1.cloud.twistlock.com" --install-host
