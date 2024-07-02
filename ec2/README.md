# EC2 Terraform Documentation

This documentation provides information on the Terraform configuration used to deploy and manage ec2 ec2 instance on AWS. The variables are defined in the `vars.tf` file, and this README explains their purpose and usage.

## Variables

### user_data_vars

Values in `user_data_vars` will be used in the `user-data.sh` script for configuration and deployments. `user-data.sh` will configure the datadog-agent, deploy ec2, app-b and configure the twistlock agent on the created EC2 instance

- **user_data_script**: Path to the user data script. Default is `"user-data.sh"`.
- **JENKINS_SECRET**: Jenkins secret name containing the Jenkins URL and API key. Default is `"Stage_Jenkins_API"`.
- **ENV_NAME**: Environment name used in tags and deployments to manage the older structure.

#### app-a configs

- **BRANCH**: Branch to clone the nginx config file.
- **DOMAIN_NAME**: app-a domain name for the ec2.

### volume_configs

Configurations for additional volumes to be attached to the instance.

- **add_on_volume_for_instance**: Boolean to determine if a new volume needs to be created and attached to the instance. Default is `false`.
- **availability_zone**: List of availability zones for the volumes.
- **size**: Size of the volume in GB.
- **encrypted**: Boolean to determine if the volume should be encrypted. Default is `true`.
- **final_snapshot**: Boolean to determine if a final snapshot should be created before volume deletion. Default is `false`.
- **iops**: IOPS for the volume. Default is `3000`.
- **type**: Volume type. Default is `"gp3"`.
- **throughput**: Throughput for the volume. Default is `125`.
- **kms_key_id**: KMS key ARN for encryption. Default is `"kms_key_arn"`.
- **tags**: Tags to be added to the volume. Do not add `Name` and `Environment` tags.

### instance_configs

Configurations for the ec2 EC2 instance.

- **region**: AWS region where the EC2 instance will be launched. Default is `"us-east-1"`.
- **number_of_instances**: Number of instances to launch with the same configurations. Default is `1`.
- **ami**: packer created AMI ID for the ec2 instance.
- **instance_type**: Instance type.
- **iam_instance_profile**: IAM role to attach to the EC2 instance. Default is `"CodeDeployDemo-EC2-Instance-Profile"`.
- **key_name**: SSH key to connect to the instance. Default is `"perf-app-a"`.
- **monitoring**: Boolean to enable monitoring. Default is `false`.
- **associate_public_ip_address**: Boolean to associate a public IP address. Default is `false`.
- **security_groups**: List of security groups to attach.
- **subnet_ids**: List of subnet IDs for the instances.

**NOTE:**  If volume need to be created, then list of `subnet_ids` for instances should be in the same `availability_zone` as volumes

#### Root Disk Configurations

- **root_disk_encrypted**: Boolean to encrypt the root disk. Default is `true`.
- **root_disk_iops**: IOPS for the root disk. Default is `3000`.
- **root_disk_kms_key_id**: KMS key ID for the root disk. Default is `"kms_key"`.
- **root_disk_throughput**: Throughput for the root disk. Default is `125`.
- **root_disk_volume_size**: Size of the root disk in GB. Default is `100`.
- **root_disk_volume_type**: Volume type for the root disk. Default is `"gp3"`.
- **tags**: Tags to be added to the EC2 instance. Do not add `Name` and `Environment` tags.

### attach_to_tg

Configurations for attaching the instance to a target group.

- **is_required**: Boolean to determine if the instance should be attached to the target group. Default is `false`.
- **target_group_arn**: ARN of the target group to attach the instance to. Default is `"target_group"`.

### elastic_ip

Configurations for attaching an Elastic IP to the instance.

- **is_required**: Boolean to determine if an Elastic IP should be created and attached. Default is `false`.
- **tags**: Tags to be added to the Elastic IP. Do not add `Name` and `Environment` tags.

## Author

- [@Hemanth](https://github.com/hemanthakumar97)