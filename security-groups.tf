resource aws_security_group "mysql" {
  name        = "poc-db"
  description = "sg for accessing RDS instance"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "web_to_db" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.instance.id
  security_group_id        = aws_security_group.mysql.id
}

resource aws_security_group "bastion" {
  name        = "poc-bastion"
  description = "sg for accessing bastion ec2"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  ingress {
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["86.57.255.92/32"]
  }
  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource aws_security_group "instance" {
  name        = "poc-instance"
  description = "sg for accessing EC2 instances"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  egress {
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "web_to_lb" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lb.id
  security_group_id        = aws_security_group.instance.id
}

resource "aws_security_group_rule" "web_from_bastion" {
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.bastion.id
  security_group_id        = aws_security_group.instance.id
}

resource aws_security_group "lb" {
  name        = "poc-lb"
  description = "sg for accessing ELB instances"
  vpc_id      = module.vpc.vpc_id
  tags        = var.tags

  ingress {
    protocol = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "lb_to_web" {
  type                     = "egress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.instance.id
  security_group_id        = aws_security_group.lb.id
}
