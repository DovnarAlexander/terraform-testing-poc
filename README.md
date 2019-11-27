# Requirements:
Covered by temporary TF code
- SSH key in SSM
- RDS credentials in SSM
# TODO:
- 443:
  * DNS
  * CERT
  * 443
- AMI
  * prebake AMI to speed up
- SSH
  * bastion -> ssm
- Some custom runner with IAM IP (Jenkins node, GitLab runner) and tools installed
# Test output
## TFLint
```bash
TFLINT_LOG=debug tflint
1 issue(s) found:

Notice: "default.mysql5.7" is default parameter group. You cannot edit it. (aws_db_instance_default_parameter_group)

  on instances.tf line 10:
  10:   parameter_group_name   = "default.mysql5.7"

Reference: https://github.com/wata727/tflint/blob/v0.12.1/docs/rules/aws_db_instance_default_parameter_group.md
```
# TFSec
```bash

11 potential problems detected:

Problem 1

  [AWS012] Resource 'aws_instance.bastion' has a public IP address associated.
  /workdir/instances.tf:27

      24 |   tags                        = merge(map("Name", "bastion"), var.tags)
      25 |   subnet_id                   = element(module.vpc.public_subnets, 0)
      26 |   vpc_security_group_ids      = list(aws_security_group.bastion.id)
      27 |   associate_public_ip_address = true
      28 |   key_name                    = aws_key_pair.key.key_name
      29 |   disable_api_termination     = false
      30 |   ebs_optimized               = true

Problem 2

  [AWS005] Resource 'aws_elb.web' is exposed publicly.
  /workdir/instances.tf:99-126

      96 |   }
      97 | }
      98 | 
      99 | resource "aws_elb" "web" {
     100 |   name    = "web-frontend"
     101 |   subnets = module.vpc.public_subnets
     102 | 
     103 |   listener {
     104 |     instance_port     = 80
     105 |     instance_protocol = "http"
     106 |     # TODO: Replace wiht HTTPS
     107 |     lb_port     = 80
     108 |     lb_protocol = "http"
     109 |   }
     110 | 
     111 |   health_check {
     112 |     healthy_threshold   = 2
     113 |     unhealthy_threshold = 10
     114 |     timeout             = 10
     115 |     target              = "TCP:80"
     116 |     interval            = 20
     117 |   }
     118 | 
     119 |   security_groups             = list(aws_security_group.lb.id)
     120 |   cross_zone_load_balancing   = false
     121 |   idle_timeout                = 100
     122 |   connection_draining         = false
     123 |   connection_draining_timeout = 100
     124 | 
     125 |   tags = merge(var.tags, map("Name", "web-frontend"))
     126 | }
     127 | 
     128 | resource "aws_lb_cookie_stickiness_policy" "web" {
     129 |   name                     = "stickiness"

Problem 3

  [AWS009] Resource 'aws_security_group.mysql' defines a fully open egress security group.
  /workdir/security-groups.tf:11

       8 |     protocol    = -1
       9 |     from_port   = 0
      10 |     to_port     = 0
      11 |     cidr_blocks = ["0.0.0.0/0"]
      12 |   }
      13 | }
      14 | 

Problem 4

  [AWS018] Resource 'aws_security_group_rule.web_to_db' should include a description for auditing purposes.
  /workdir/security-groups.tf:15-22

      12 |   }
      13 | }
      14 | 
      15 | resource "aws_security_group_rule" "web_to_db" {
      16 |   type                     = "ingress"
      17 |   from_port                = 3306
      18 |   to_port                  = 3306
      19 |   protocol                 = "tcp"
      20 |   source_security_group_id = aws_security_group.instance.id
      21 |   security_group_id        = aws_security_group.mysql.id
      22 | }
      23 | 
      24 | resource aws_security_group "bastion" {
      25 |   name        = "poc-bastion"

Problem 5

  [AWS008] Resource 'aws_security_group.bastion' defines a fully open ingress security group.
  /workdir/security-groups.tf:34

      31 |     protocol    = "tcp"
      32 |     from_port   = 22
      33 |     to_port     = 22
      34 |     cidr_blocks = ["0.0.0.0/0"]
      35 |   }
      36 |   egress {
      37 |     protocol    = -1

Problem 6

  [AWS009] Resource 'aws_security_group.bastion' defines a fully open egress security group.
  /workdir/security-groups.tf:40

      37 |     protocol    = -1
      38 |     from_port   = 0
      39 |     to_port     = 0
      40 |     cidr_blocks = ["0.0.0.0/0"]
      41 |   }
      42 | }
      43 | 

Problem 7

  [AWS009] Resource 'aws_security_group.instance' defines a fully open egress security group.
  /workdir/security-groups.tf:54

      51 |     protocol    = -1
      52 |     from_port   = 0
      53 |     to_port     = 0
      54 |     cidr_blocks = ["0.0.0.0/0"]
      55 |   }
      56 | }
      57 | 

Problem 8

  [AWS018] Resource 'aws_security_group_rule.web_to_lb' should include a description for auditing purposes.
  /workdir/security-groups.tf:58-65

      55 |   }
      56 | }
      57 | 
      58 | resource "aws_security_group_rule" "web_to_lb" {
      59 |   type                     = "ingress"
      60 |   from_port                = 80
      61 |   to_port                  = 80
      62 |   protocol                 = "tcp"
      63 |   source_security_group_id = aws_security_group.lb.id
      64 |   security_group_id        = aws_security_group.instance.id
      65 | }
      66 | 
      67 | resource "aws_security_group_rule" "web_from_bastion" {
      68 |   type                     = "ingress"

Problem 9

  [AWS018] Resource 'aws_security_group_rule.web_from_bastion' should include a description for auditing purposes.
  /workdir/security-groups.tf:67-74

      64 |   security_group_id        = aws_security_group.instance.id
      65 | }
      66 | 
      67 | resource "aws_security_group_rule" "web_from_bastion" {
      68 |   type                     = "ingress"
      69 |   from_port                = 22
      70 |   to_port                  = 22
      71 |   protocol                 = "tcp"
      72 |   source_security_group_id = aws_security_group.bastion.id
      73 |   security_group_id        = aws_security_group.instance.id
      74 | }
      75 | 
      76 | resource aws_security_group "lb" {
      77 |   name        = "poc-lb"

Problem 10

  [AWS008] Resource 'aws_security_group.lb' defines a fully open ingress security group.
  /workdir/security-groups.tf:87

      84 |     # TODO: Replace wiht HTTPS
      85 |     from_port   = 80
      86 |     to_port     = 80
      87 |     cidr_blocks = ["0.0.0.0/0"]
      88 |   }
      89 | }
      90 | 

Problem 11

  [AWS018] Resource 'aws_security_group_rule.lb_to_web' should include a description for auditing purposes.
  /workdir/security-groups.tf:91-98

      88 |   }
      89 | }
      90 | 
      91 | resource "aws_security_group_rule" "lb_to_web" {
      92 |   type                     = "egress"
      93 |   from_port                = 80
      94 |   to_port                  = 80
      95 |   protocol                 = "tcp"
      96 |   source_security_group_id = aws_security_group.instance.id
      97 |   security_group_id        = aws_security_group.lb.id
      98 | }
      99 | 
```
# Terraform Compliance
```bash
terraform plan -out compliance.out -var-file ./variables.tfvars
terraform-compliance --planfile compliance.out --features compliance/

terraform-compliance v1.0.57 initiated

. Converting terraform plan file.
* Features  : /Users/aliaksandr.dounar/Work/Projects/personal/terraform-testing-poc/compliance
* Plan File : /Users/aliaksandr.dounar/Work/Projects/personal/terraform-testing-poc/compliance.out.json

. Running tests.
Feature: All resources should be tagged  # /Users/aliaksandr.dounar/Work/Projects/personal/terraform-testing-poc/compliance/basic.feature

    Scenario: Ensure all resources have tags
        Given I have resource that supports tags defined
        Then it must contain tags
          Failure: aws_launch_template.web (aws_launch_template) does not have tags property.
        And its value must not be null

1 features (0 passed, 1 failed)
1 scenarios (0 passed, 1 failed)
3 steps (1 passed, 1 failed, 1 skipped)
Run 1574846225 finished within a moment
```