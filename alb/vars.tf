variable "alb_configs" {
    default = {
        name                        = "test-lb-tf"
        region                      = "us-east-1"
        internal                    = false
        load_balancer_type          = "application"
        security_groups             = [<security_group_ids>]
        subnets                     = [<subnet_ids>]
        idle_timeout                = 180
        enable_deletion_protection  = false
        access_logs_enabled         = true
        access_logs_bucket          = "alblogs_bucket"
        waf_enable                  = false                 # Make it false when no need to enable the WAF
        waf_acl_arn                 = <waf_web_acl_arn> 
        
        tags = {
            Environment = "test"
        }

    }
}

variable "target_group_configs" {
    type = map(string)
    default = {
        new_target_group                = false                          # Make it true if target group need to be created
        target_id                       = <instance_id>                  # Attach the target instance to the newly created target group
        name                            = "my-target-group"
        port                            = 80
        protocol                        = "HTTP"
        vpc_id                          = <vpc_id>
        stickiness_type                 = "lb_cookie"
        stickiness_cookie_duration      = 14400 # 4 hours in seconds
    }
}

variable "http_listener_configs" {
    type = map(string)
    default = {
        default_action_target_group_arn = ""
    }
}

variable "https_listener_configs" {
    type = map(string)
    default = {
        ssl_policy                      = "ELBSecurityPolicy-TLS-1-2-2017-01"           # Change to your desired SSL policy
        certificate_arn                 = <certificate_arn>                             # Replace with the app-a domain SSL certificate ARN
        is_addon_certificate_arn        = false                                         # Make it false when app-b domain certificate is not required in SNI
        app-b_certificate_arn           = <certificate_arn>                             # Replace with the ap-b domain SSL certificate ARN
        default_action_target_group_arn = ""                                            # default requests will go to this target group, no need to mention if we are creating a new target group
    }
}

# Change the respective ARNs and priority
variable "alb_rules" {
    default = {
        domains_list = ["app-a.domain.com", "app-b.domain.com"]                 # app-a and app-b domains or hosts

        app-a_rule_priority = 1
        app-a_target_group_arn = <app-a-target-group-arn>

        app-b-rule_priority = 2
        app-b-target_group_arn = <app-b-target-group-arn>
    }
}

