resource "aws_iam_role_policy_attachment" "ghe_worker_ec2_SSM" {
  role       = var.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ghe_worker_ec2_CW_logs" {
  role       = var.iam_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}





resource "aws_iam_role_policy_attachment" "ghe_worker_ssm" {
  role       = var.iam_ssm_role
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonSSMAutomationRole"
}

resource "aws_iam_role_policy_attachment" "ghe_worker_ssm_asg" {
  role       = var.iam_ssm_role
  policy_arn = "arn:aws:iam::aws:policy/AutoScalingFullAccess"
}




# data "aws_iam_policy_document" "ghes_runner_ssm" {
#   statement {
#     sid = "SSMAutomation"

#     actions = [
#       "iam:PassRole",
#     ]

#     resources = [
#       replace("${aws_ssm_document.ghe_runner_terminate.arn}:$LATEST", "document/", "automation-definition/"),
#     ]
#   }

# }

# resource "aws_iam_policy" "cw_ssm" {
#   name_prefix   = "ghes_runner_terminate_ssm_${var.environment}_"
#   path   = "/acct-managed/"
#   policy = data.aws_iam_policy_document.ghes_runner_terminate.json
# }

# resource "aws_iam_role_policy_attachment" "ghe_worker_ssm_custom" {
#   role       = var.iam_ssm_role
#   policy_arn = aws_iam_policy.ghes_runner_ssm.arn
# }







resource "aws_iam_role_policy_attachment" "ghe_worker_cwe" {
  role       = var.iam_cwa_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchEventsFullAccess"
}

resource "aws_iam_role_policy_attachment" "ghe_worker_cwe2" {
  role       = var.iam_cwa_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEventBridgeFullAccess"
}

resource "aws_iam_role_policy_attachment" "ghe_worker_cwe3" {
  role       = var.iam_cwa_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
}



data "aws_iam_policy_document" "ghes_runner_terminate" {
  statement {
    sid = "SSMautomationPermissiontoCompleteLifecyclePolicy"

    actions = [
      "ssm:StartautomationExecution",
    ]

    resources = [
      replace("${aws_ssm_document.ghe_runner_terminate.arn}:$LATEST", "document/", "automation-definition/"),
    ]
  }
  statement {
    sid = "PassRoleSSMAutomationPolicy"

    actions = [
      "iam:PassRole",
    ]

    resources = [
      data.aws_iam_role.iam_ssm_role.arn
    ]

    effect = "Allow"
  }

}

resource "aws_iam_policy" "cw_ssm" {
  name_prefix = "ghes_runner_terminate_cw_event_${var.environment}_"
  path        = "/acct-managed/"
  policy      = data.aws_iam_policy_document.ghes_runner_terminate.json
}

resource "aws_iam_role_policy_attachment" "ghe_worker_cwe_custom" {
  role       = var.iam_cwa_role_name
  policy_arn = aws_iam_policy.cw_ssm.arn
}