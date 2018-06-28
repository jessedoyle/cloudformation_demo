provider "aws" {
  region = "us-west-2"
}

variable "key_pair_name" {
  type        = "string"
  description = "The AWS key-pair name for instance SSH keys."
  default     = "jesse-aws"
}

resource "aws_vpc" "app_vpc" {
  cidr_block           = "172.10.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  instance_tenancy     = "default"
}

resource "aws_subnet" "app_subnet_a" {
  availability_zone       = "us-west-2a"
  cidr_block              = "172.10.1.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.app_vpc.id}"
}

resource "aws_subnet" "app_subnet_b" {
  availability_zone       = "us-west-2b"
  cidr_block              = "172.10.2.0/24"
  map_public_ip_on_launch = true
  vpc_id                  = "${aws_vpc.app_vpc.id}"
}

resource "aws_internet_gateway" "app_internet_gateway" {
  vpc_id = "${aws_vpc.app_vpc.id}"
}

resource "aws_route_table" "app_route_table" {
  vpc_id = "${aws_vpc.app_vpc.id}"
}

resource "aws_route" "app_route_to_internet" {
  route_table_id         = "${aws_route_table.app_route_table.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.app_internet_gateway.id}"
}

resource "aws_route_table_association" "app_route_to_subnet_a" {
  subnet_id      = "${aws_subnet.app_subnet_a.id}"
  route_table_id = "${aws_route_table.app_route_table.id}"
}

resource "aws_route_table_association" "app_route_to_subnet_b" {
  subnet_id      = "${aws_subnet.app_subnet_b.id}"
  route_table_id = "${aws_route_table.app_route_table.id}"
}

resource "aws_security_group" "app_load_balancer_security_group" {
  vpc_id = "${aws_vpc.app_vpc.id}"

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags {
    Resource = "load_balancer"
  }
}

resource "aws_security_group" "app_instance_security_group" {
  vpc_id = "${aws_vpc.app_vpc.id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }

  tags {
    Resource = "ec2_instance"
  }
}

resource "aws_iam_role" "app_instance_role" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Effect": "Allow",
      "Action": [
        "sts:AssumeRole"
      ]
    }
  ]
}
EOF
}

resource "aws_iam_policy_attachment" "app_code_deploy_managed_policy" {
  name       = "app-code-deploy-managed-policy"
  roles      = ["${aws_iam_role.app_instance_role.name}"]
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSCodeDeployRole"
}

resource "aws_iam_instance_profile" "app_instance_profile" {
  role = "${aws_iam_role.app_instance_role.name}"
}

resource "aws_alb" "app_load_balancer" {
  internal           = false
  load_balancer_type = "application"

  security_groups = [
    "${aws_security_group.app_load_balancer_security_group.id}",
  ]

  subnets = [
    "${aws_subnet.app_subnet_a.id}",
    "${aws_subnet.app_subnet_b.id}",
  ]

  ip_address_type = "ipv4"
}

resource "aws_alb_target_group" "app_load_balancer_target_group" {
  port     = 80
  vpc_id   = "${aws_vpc.app_vpc.id}"
  protocol = "HTTP"

  health_check {
    interval          = 5
    path              = "/health_check"
    protocol          = "HTTP"
    timeout           = 2
    healthy_threshold = 2
    matcher           = "200"
  }
}

resource "aws_alb_listener" "app_load_balancer_listener" {
  default_action {
    target_group_arn = "${aws_alb_target_group.app_load_balancer_target_group.arn}"
    type             = "forward"
  }

  load_balancer_arn = "${aws_alb.app_load_balancer.arn}"
  port              = 80
  protocol          = "HTTP"
}

data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["self"]

  filter {
    name   = "name"
    values = ["cloudformation-demo-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_launch_configuration" "app_instance_launch_configuration" {
  image_id                    = "${data.aws_ami.amazon_linux.id}"
  instance_type               = "t2.micro"
  iam_instance_profile        = "${aws_iam_instance_profile.app_instance_profile.id}"
  ebs_optimized               = false
  associate_public_ip_address = true
  enable_monitoring           = true
  key_name                    = "${var.key_pair_name}"
  security_groups             = ["${aws_security_group.app_instance_security_group.id}"]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_placement_group" "app_placement_group" {
  name     = "spread-placement-group"
  strategy = "spread"
}

resource "aws_autoscaling_group" "app_autoscaling_group" {
  max_size                  = 4
  min_size                  = 2
  desired_capacity          = 2
  placement_group           = "${aws_placement_group.app_placement_group.id}"
  availability_zones        = ["us-west-2a", "us-west-2b"]
  default_cooldown          = 120
  health_check_grace_period = 420
  health_check_type         = "ELB"
  launch_configuration      = "${aws_launch_configuration.app_instance_launch_configuration.name}"
  target_group_arns         = ["${aws_alb_target_group.app_load_balancer_target_group.arn}"]
  wait_for_elb_capacity     = 2

  vpc_zone_identifier = [
    "${aws_subnet.app_subnet_a.id}",
    "${aws_subnet.app_subnet_b.id}",
  ]

  tags = [
    {
      key                 = "live"
      value               = "true"
      propagate_at_launch = true
    },
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_subnet_group" "app_db_subnet_group" {
  subnet_ids = [
    "${aws_subnet.app_subnet_a.id}",
    "${aws_subnet.app_subnet_b.id}",
  ]
}

resource "aws_security_group" "app_db_security_group" {
  vpc_id = "${aws_vpc.app_vpc.id}"

  ingress {
    cidr_blocks = ["${aws_vpc.app_vpc.cidr_block}"]
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
  }

  egress {
    cidr_blocks = ["${aws_vpc.app_vpc.cidr_block}"]
    protocol    = "tcp"
    from_port   = 5432
    to_port     = 5432
  }
}

resource "random_string" "app_db_password" {
  length  = 64
  special = false
}

resource "aws_db_instance" "app_db_instance" {
  allocated_storage           = 5
  storage_type                = "gp2"
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  availability_zone           = "us-west-2a"
  backup_retention_period     = 0
  apply_immediately           = true
  db_subnet_group_name        = "${aws_db_subnet_group.app_db_subnet_group.name}"
  engine                      = "postgres"
  engine_version              = "10.1"
  instance_class              = "db.t2.micro"
  multi_az                    = false
  port                        = 5432
  password                    = "${random_string.app_db_password.result}"
  skip_final_snapshot         = true
  publicly_accessible         = false
  storage_encrypted           = false
  username                    = "root"
  vpc_security_group_ids      = ["${aws_security_group.app_db_security_group.id}"]
}

data "template_file" "production_environment" {
  template = "${file("./templates/.env.tpl")}"

  vars {
    database_host     = "${aws_db_instance.app_db_instance.address}"
    database_password = "${random_string.app_db_password.result}"
    database_port     = "${aws_db_instance.app_db_instance.port}"
  }
}

resource "local_file" "production_environment" {
  content  = "${data.template_file.production_environment.rendered}"
  filename = "${path.module}/.env.production"
}
