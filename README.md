# terraform-aws-action-runner
Terraform module to setup aws action runners

### Required inputs:

#### ghe_pat

A Personal Access Token that the runners will use for regestration and deregestration

#### nr_key

A vaild New Relic API key to register the EC2 with

#### nr_account

A New Relic account to register the EC2 to

#### iam_ip_arn

A New Relic account to register the EC2 to

#### iam_role_name

A New Relic account to register the EC2 to

#### environment

A namespace varable so that mutiple installs can exisit in the same envroment. Generally this would be something like `nonprod`, `dev`, `test`, `prod`, etc. 

#### ghes_base_url

The base url for your GHES instance. i.e. `https://ghes.ezcorp.com`
