# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "instance_sg"
  description = "Used in the terraform"

  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Our elb security group to access
# the ELB over HTTP
resource "aws_security_group" "elb" {
  name        = "elb_sg"
  description = "Used in the terraform"

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "web" {
  name = "mandelbrot-elb"

  # Same availability zone as our instances
  availability_zones = ["${split(",", var.availability_zones)}"]
  security_groups    = ["${aws_security_group.elb.id}"]

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 4
    timeout             = 3
    target              = "HTTP:80/"
    interval            = 60
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400
}

resource "aws_lb_cookie_stickiness_policy" "default" {
  name                     = "lbpolicy"
  load_balancer            = "${aws_elb.web.id}"
  lb_port                  = 80
  cookie_expiration_period = 600
}

resource "aws_autoscaling_group" "web-asg" {
  availability_zones = ["${split(",", var.availability_zones)}"]
  name = "mandelbrot-asg"
  max_size              = "${var.asg_max}"
  min_size              = "${var.asg_min}"
  desired_capacity      = "${var.asg_desired}"
  force_delete          = true
  launch_configuration  = "${aws_launch_configuration.web-lc.name}"
  load_balancers        = ["${aws_elb.web.name}"]

  tag {
    key                 = "Name"
    value               = "web-asg"
    propagate_at_launch = "true"
  }
}

resource "aws_launch_configuration" "web-lc" {
  name          = "mandelbrot-lc"
  image_id      = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type = "${var.instance_type}"
  iam_instance_profile = "${aws_iam_instance_profile.deploy_instance_profile.name}"
  # Security group
  security_groups = ["${aws_security_group.default.id}"]
  user_data       = "${file("userdata2.sh")}"
  key_name        = "${var.key_name}"
}

resource "aws_autoscaling_policy" "scale-up" {
  name = "mandelbrot-scale-up"
  scaling_adjustment = 50
  adjustment_type = "PercentChangeInCapacity"
  cooldown = 300
  autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
}

resource "aws_autoscaling_policy" "scale-down" {
    name = "mandelbrot-scale-down"
    scaling_adjustment = -1
    adjustment_type = "ChangeInCapacity"
    cooldown = 300
    autoscaling_group_name = "${aws_autoscaling_group.web-asg.name}"
}

resource "aws_cloudwatch_metric_alarm" "highcpualarm" {
    alarm_name = "mandelbrot-highcpualarm"
    comparison_operator = "GreaterThanThreshold"
    evaluation_periods = "2"
    metric_name = "CPUUtilization"
    namespace = "AWS/EC2"
    period = "60"
    statistic = "Average"
    threshold = "70"
    dimensions {
        AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
    }
    alarm_description = "This metric monitor ec2 cpu utilization"
    alarm_actions = ["${aws_autoscaling_policy.scale-up.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "lowcpualarm" {
  alarm_name = "mandelbrot-lowcpualarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods = "2"
  metric_name = "CPUUtilization"
  namespace = "AWS/EC2"
  period = "60"
  statistic = "Average"
  threshold = "36"
  dimensions {
      AutoScalingGroupName = "${aws_autoscaling_group.web-asg.name}"
  }
  alarm_description = "This metric monitor ec2 cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.scale-down.arn}"]
}

resource "aws_cloudwatch_metric_alarm" "highlatency" {
  alarm_name = "mandelbrot-highlatencyalarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods = "1"
  metric_name = "Latency"
  namespace = "AWS/ELB"
  period = "60"
  statistic = "Average"
  threshold = "3"
  dimensions {
      LoadBalancerName = "${aws_elb.web.name}"
  }
  alarm_description = "This metric monitor ec2 cpu utilization"
  alarm_actions = ["${aws_autoscaling_policy.scale-up.arn}"]
}

resource "aws_codedeploy_app" "aws-mandelbrot" {
  name = "aws_mandelbrot"
}

resource "aws_iam_role_policy" "deploy_policy" {
    name = "deploy_policy"
    role = "${aws_iam_role.deploy_role.id}"
    policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "autoscaling:CompleteLifecycleAction",
                "autoscaling:DeleteLifecycleHook",
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeLifecycleHooks",
                "autoscaling:PutLifecycleHook",
                "autoscaling:RecordLifecycleActionHeartbeat",
                "ec2:DescribeInstances",
                "ec2:DescribeInstanceStatus",
                "s3:Get*",
                "s3:List*",
                "tag:GetTags",
                "tag:GetResources"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "deploy_instance_profile" {
    name = "deploy_instance_profile"
    roles = ["${aws_iam_role.deploy_role.name}"]
}

resource "aws_iam_role" "deploy_role" {
    name = "deploy_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "codedeploy.amazonaws.com",
          "codedeploy.eu-west-1.amazonaws.com",
          "ec2.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_codedeploy_deployment_group" "mandelbrot" {
    app_name = "${aws_codedeploy_app.aws-mandelbrot.name}"
    deployment_group_name = "mandelbrot"
    service_role_arn = "${aws_iam_role.deploy_role.arn}"
    autoscaling_groups = ["${aws_autoscaling_group.web-asg.id}"]
}

resource "aws_s3_bucket" "codedeploy" {
    bucket = "mandelbrot-codedeploy"
    acl = "private"
    force_destroy = true

    tags {
        Name = "codedeploy"
        Environment = "Dev"
    }
}
