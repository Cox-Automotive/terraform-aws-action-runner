#Setup a hook for when an instance is going to terminate
resource "aws_autoscaling_lifecycle_hook" "ghes_runner_terminate" {
  name                   = "ghes_runner_terminate_${var.environment}"
  autoscaling_group_name = aws_autoscaling_group.ghes_runner.name
  default_result         = "CONTINUE"
  heartbeat_timeout      = 600
  lifecycle_transition   = "autoscaling:EC2_INSTANCE_TERMINATING"
}


resource "aws_ssm_document" "ghe_runner_terminate" {
  name            = "ghe_runner_terminate_${var.environment}"
  document_type   = "Automation"
  document_format = "YAML"
  content         = data.template_file.terminate_hook.rendered
}


data "template_file" "terminate_hook" {
  template = file("${path.module}/terminate_hook.yaml")

  vars = {
    ghe_pat           = var.ghe_pat
    ghe_pat_ssm_name  = aws_ssm_parameter.ghes_pat_runner_reg.name
    ghes_base_url     = var.ghes_base_url
  }
}


resource "aws_cloudwatch_event_rule" "terminate_hook" {
  name_prefix       = "ghe_runner_terminate_${var.environment}_"
  description = "Remove runner on termination"

  event_pattern = <<EOF
{
  "source": [
    "aws.autoscaling"
  ],
  "detail-type": [
    "EC2 Instance-terminate Lifecycle Action"
  ],
  "detail": {
    "AutoScalingGroupName": [
      "${aws_autoscaling_group.ghes_runner.name}"
    ]
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "terminate_hook" {
  target_id = "StopInstance"
  arn       = replace("${aws_ssm_document.ghe_runner_terminate.arn}:$LATEST", "document/", "automation-definition/") 
  rule      = aws_cloudwatch_event_rule.terminate_hook.name
  role_arn  = data.aws_iam_role.iam_cwa_role_name.arn
  input_transformer {
    input_paths = {
      asgname   = "$.detail.AutoScalingGroupName",
      instanceid = "$.detail.EC2InstanceId",
      lchname   = "$.detail.LifecycleHookName",
    }
    input_template = <<EOF
     {
        "InstanceId": [<instanceid>],
        "ASGName": [<asgname>],
        "LCHName": [<lchname>],
        "automationAssumeRole": ["${data.aws_iam_role.iam_ssm_role.arn}"]
     }
    EOF
    }
}

data "aws_iam_policy_document" "ssm_lifecycle_trust" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}
