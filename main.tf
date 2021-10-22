resource "aws_autoscaling_policy" "ghes_runner_scale_up" {
  name                   = "ghes_runner_up_${var.environment}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ghes_runner.name
  cooldown               = 300
}

resource "aws_autoscaling_policy" "ghes_runner_scale_down" {
  name                   = "ghes_runner_down_${var.environment}"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.ghes_runner.name
  cooldown               = 300
}

resource "aws_cloudwatch_metric_alarm" "cpu-high" {
  alarm_name          = "cpu-util-high-runner-${var.environment}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "10"
  alarm_description   = "This metric monitors ec2 CPU for high utilization on agent hosts"
  alarm_actions = [
    aws_autoscaling_policy.ghes_runner_scale_up.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ghes_runner.name
  }
}

resource "aws_cloudwatch_metric_alarm" "cpu-low" {
  alarm_name          = "cpu-util-low-runner-${var.environment}"
  comparison_operator = "LessThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = "120"
  statistic           = "Average"
  threshold           = "5"
  alarm_description   = "This metric monitors ec2 CPU for low utilization on agent hosts"
  alarm_actions = [
    aws_autoscaling_policy.ghes_runner_scale_down.arn
  ]
  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.ghes_runner.name
  }
}


resource "aws_autoscaling_group" "ghes_runner" {
  name_prefix         = "ghes_runner_${var.environment}_"
  vpc_zone_identifier = data.aws_subnet_ids.subnets.ids
  max_size            = var.pool_size_max
  min_size            = var.pool_size_min
  metrics_granularity = "1Minute"
  enabled_metrics     = ["GroupMinSize", "GroupMaxSize", "GroupMaxSize", "GroupMaxSize", "GroupPendingInstances", "GroupTotalInstances"]

  launch_template {
    id      = aws_launch_template.ghes_runner.id
    version = aws_launch_template.ghes_runner.latest_version
  }
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 49
    }
    #triggers = ["tag"]
  }
}



# This takes the raw yaml file and performs simple var replacement. 
#TODO: Take the sleep and optionally the status commands out of the yaml 
data "template_file" "init_script" {
  template = file("${path.module}/init.yaml")

  vars = {
    package_upgrade    = "true"
    ghe_pat            = var.ghe_pat
    nr_key             = var.nr_key
    nr_account         = var.nr_account
    ghes_base_url      = var.ghes_base_url
    ghe_pat_ssm_name   = aws_ssm_parameter.ghes_pat_runner_reg.name
    ghes_runner_target = var.ghes_runner_target
    ghes_runner_labels = var.ghes_runner_labels
    ghes_runner_group  = var.ghes_runner_group
  }
}

# Takes the plaintext yaml output of the previous data source and formats it into a cloudinit file. 
data "template_cloudinit_config" "init_script" {
  gzip          = true
  base64_encode = true

  # Main cloud-config configuration file.
  part {
    filename     = "init.cfg"
    content_type = "text/cloud-config"
    content      = data.template_file.init_script.rendered
  }
}

#The lanch template defines the attributes of the EC2 that the auto scaleing group will create. 
resource "aws_launch_template" "ghes_runner" {
  name_prefix   = "ghes_runner_${var.environment}_"
  image_id      = data.aws_ssm_parameter.ecs_ami.value
  instance_type = "t3a.medium"
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = ["${aws_security_group.ghes_runner.id}"]
  }
  iam_instance_profile {
    #name = "${aws_iam_instance_profile.ghe_worker.name}" #Pure AWS
    arn = var.iam_ip_arn
  }
  monitoring {
    enabled = true
  }
  user_data = data.template_cloudinit_config.init_script.rendered

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "GHE_Runner_${var.environment}"

    }
  }
}

#Need to let the EC2 Worker access the internet
resource "aws_security_group" "ghes_runner" {
  name_prefix = "ghes_runner_ec2_${var.environment}_"
  description = "GHES Runner EC2 Default"
  vpc_id      = data.aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ssm_parameter" "ghes_pat_runner_reg" {
  name  = "/actions/${var.environment}/ghes_pat_runner_reg"
  type  = "SecureString"
  value = var.ghe_pat
}

