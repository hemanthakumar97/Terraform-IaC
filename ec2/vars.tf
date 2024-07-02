# Values in user_data_vars will be used in user-data.sh script for deployments
variable "user_data_vars" {
    default = {
        user_data_script = "user-data.sh"       # User data script path
        JENKINS_SECRET = "Jenkins_API"    # Jenkins secret name which has the Jenkis URL and API key
        ENV_NAME = "test"                       # Environment name, it will used in tags and deployments to manage the older structure

        # app-a configs
        BRANCH = "app-a-e45.0.0"                   # Branch to clone the nginx config file
        DOMAIN_NAME = "app-a.domain.com"    # app-a domain name for ec2
    }
}

variable "volume_configs" {
    default = {
        add_on_volume_for_instance  = false                 # Make it true if new volume needs to be created and attached to the instance
        availability_zone           = ["us-east-1c", "us-east-1d"]          # Availability zones for volume
        size                        = 50
        encrypted                   = true
        final_snapshot              = false
        iops                        = 3000
        type                        = "gp3"
        throughput                  = 125
        kms_key_id                  = <kms_key_arn>
        tags                        = {
                                    }       # These tags will be added to the volume, dont add Name and Environment tags
    }
}

variable "instance_configs" {
    default = {
        region                      = "us-east-1"                   # Region where the ec2 instance need to be launched
        number_of_instances         = 1                             # No. of instnaces need to be launched with same configs
        ami                         = <ami_id>                      # Use the packer created AMI here
        instance_type               = "t4g.small"                   # Instance type
        iam_instance_profile        = "EC2-Instance-Profile"        # Role to attach to the ec2 instance
        key_name                    = <ssh_key_name">               # SSH key to connect to the instance
        monitoring                  = false
        associate_public_ip_address = false                         # Make it true if public ip is required, NOTE: it should be false if you are attaching the elastic ip
        security_groups             = [<sg_group_ids>]
        subnet_ids                  = [<subnet_ids>]                # Subnet ids, List should be having [az-1c subnet, az-1d subnet]

        # Below are the root disk configurations
        root_disk_encrypted         = true
        root_disk_iops              = 3000
        root_disk_kms_key_id        = <kms_key_id>
        root_disk_throughput        = 125
        root_disk_volume_size       = 100
        root_disk_volume_type       = "gp3"
        tags                        = {         
                                    }       # These tags will be added to the ec2-instance, dont add Name and Environment tags
    }
}

variable "attach_to_tg" {
    default = {
        is_required         = false                  # true: attach the created instance to the below target group, false: target group atatchment will be skipped       
        target_group_arn    = <target_group_arn>     # target group ARN to attach the crated instance
    }
}

variable "elastic_ip" {
    default = {
        is_required     = false         # Make it true if elastic ip need to be attached to the instance
        tags            = {           
                        }               # These tags will be added to the eip, dont add Name and Environment tags
    }
}
