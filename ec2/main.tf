resource "aws_ebs_volume" "ebs_volume" {
  count               = var.volume_configs.add_on_volume_for_instance ? var.instance_configs.number_of_instances : 0
  availability_zone   = element(var.volume_configs.availability_zone, count.index % length(var.volume_configs.availability_zone))
  size                = var.volume_configs.size
  encrypted           = var.volume_configs.encrypted
  final_snapshot      = var.volume_configs.final_snapshot
  iops                = var.volume_configs.iops
  type                = var.volume_configs.type
  throughput          = var.volume_configs.throughput
  kms_key_id          = var.volume_configs.kms_key_id
  tags = merge(
            var.volume_configs.tags,
            {
              Name        = "app-a-${count.index + 1}-volume"
              Environment = "${var.user_data_vars.ENV_NAME}"
            }
          )
}

resource "aws_instance" "ec2_instance" {
    count                       = var.instance_configs.number_of_instances
    ami                         = var.instance_configs.ami
    instance_type               = var.instance_configs.instance_type
    iam_instance_profile        = var.instance_configs.iam_instance_profile
    key_name                    = var.instance_configs.key_name
    monitoring                  = var.instance_configs.monitoring
    associate_public_ip_address = var.instance_configs.associate_public_ip_address
    security_groups             = var.instance_configs.security_groups
    subnet_id                   = element(var.instance_configs.subnet_ids, count.index % length(var.instance_configs.subnet_ids))
#    availability_zone          = var.instance_configs.availability_zone

    root_block_device {
        encrypted               = var.instance_configs.root_disk_encrypted
        iops                    = var.instance_configs.root_disk_iops
        kms_key_id              = var.instance_configs.root_disk_kms_key_id
        throughput              = var.instance_configs.root_disk_throughput
        volume_size             = var.instance_configs.root_disk_volume_size
        volume_type             = var.instance_configs.root_disk_volume_type
    }

    metadata_options {
        http_tokens = "required"  # Specifies the IMDSv2 requirement
    }

    user_data = templatefile(var.user_data_vars.user_data_script, {
        ENV_NAME = var.user_data_vars.ENV_NAME
        JENKINS_SECRET = var.user_data_vars.JENKINS_SECRET
        BRANCH = var.user_data_vars.BRANCH
        DOMAIN_NAME = var.user_data_vars.DOMAIN_NAME
    })

    tags = merge(
            var.instance_configs.tags,
            {
              Name        = "app-a-${var.user_data_vars.ENV_NAME}-appserver-${count.index + 1}"
              Environment = "${var.user_data_vars.ENV_NAME}"
            }
          )
}

resource "aws_eip" "elastic_ip" {
    count     = var.elastic_ip.is_required ? var.instance_configs.number_of_instances : 0
    instance  = aws_instance.ec2_instance[count.index].id
    tags = merge(
            var.elastic_ip.tags,
            {
              Name        = "app-a-${var.user_data_vars.ENV_NAME}-appserver-${count.index + 1}-eip"
              Environment = "${var.user_data_vars.ENV_NAME}"
            }
          )
}

resource "aws_volume_attachment" "ebs_volume_attachment" {
  count               = var.volume_configs.add_on_volume_for_instance ? var.instance_configs.number_of_instances : 0
  device_name         = "/dev/sdf"
  volume_id           = aws_ebs_volume.ebs_volume[count.index].id
  instance_id         = aws_instance.ec2_instance[count.index].id
}

resource "aws_lb_target_group_attachment" "atach_to_tg" {
  count               = var.attach_to_tg.is_required ? var.instance_configs.number_of_instances : 0
  target_group_arn    = var.attach_to_tg.target_group_arn
  target_id           = aws_instance.ec2_instance[count.index].id
}
