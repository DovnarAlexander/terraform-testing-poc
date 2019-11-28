resource "aws_db_instance" "mysql" {
  allocated_storage      = 20
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7"
  instance_class         = "db.t3.micro"
  name                   = "wordpress"
  username               = data.aws_ssm_parameter.db_user.value
  password               = data.aws_ssm_parameter.db_password.value
  parameter_group_name   = "default.mysql5.7"
  vpc_security_group_ids = ["${aws_security_group.mysql.id}"]
  db_subnet_group_name   = module.vpc.database_subnet_group
  skip_final_snapshot    = true
}

resource "aws_key_pair" "key" {
  key_name   = "poc"
  public_key = data.aws_ssm_parameter.ssh_public.value
}

resource "aws_instance" "bastion" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.nano"
  tags                        = merge(map("Name", "bastion"), var.tags)
  subnet_id                   = element(module.vpc.public_subnets, 0)
  vpc_security_group_ids      = list(aws_security_group.bastion.id)
  associate_public_ip_address = true
  key_name                    = aws_key_pair.key.key_name
  disable_api_termination     = false
  ebs_optimized               = true
  monitoring                  = false
}

resource "aws_launch_template" "web" {
  name = "poc-web"

  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 20
      encrypted   = true
    }
  }
  ebs_optimized = true
  image_id      = data.aws_ami.ubuntu.id

  instance_type = "t3.micro"
  key_name      = aws_key_pair.key.key_name
  monitoring {
    enabled = false
  }
  vpc_security_group_ids = [aws_security_group.instance.id]

  tag_specifications {
    resource_type = "instance"
    tags          = merge(map("Name", "web"), var.tags)
  }
  tag_specifications {
    resource_type = "volume"
    tags          = var.tags
  }

  user_data = base64encode(
    templatefile(
      "${path.module}/files/userdata.sh",
      {
        db_name = "wordpress",
        db_user = data.aws_ssm_parameter.db_user.value,
        db_host = aws_db_instance.mysql.endpoint,
        db_pass = data.aws_ssm_parameter.db_password.value,
        fqdn    = aws_elb.web.dns_name, # TODO: Replace with valid FQDN
      }
    )
  )
}

resource "aws_autoscaling_group" "web" {
  vpc_zone_identifier       = module.vpc.private_subnets
  desired_capacity          = 1
  max_size                  = 1
  min_size                  = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  tags = [
    {
      key                 = "Name"
      value               = "Web-PoC"
      propagate_at_launch = false
    }
  ]
  load_balancers = list(aws_elb.web.id)

  launch_template {
    id      = aws_launch_template.web.id
    version = "$Latest"
  }
}

resource "aws_elb" "web" {
  name    = "web-frontend"
  subnets = module.vpc.public_subnets

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port     = 443
    lb_protocol = "https"
    ssl_certificate_id = data.aws_acm_certificate.poc.arn
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 10
    timeout             = 10
    target              = "TCP:80"
    interval            = 20
  }

  security_groups             = list(aws_security_group.lb.id)
  cross_zone_load_balancing   = false
  idle_timeout                = 100
  connection_draining         = false
  connection_draining_timeout = 100

  tags = merge(var.tags, map("Name", "web-frontend"))
}

resource "aws_lb_cookie_stickiness_policy" "web" {
  name                     = "stickiness"
  load_balancer            = aws_elb.web.id
  lb_port                  = 443
  cookie_expiration_period = 600
}