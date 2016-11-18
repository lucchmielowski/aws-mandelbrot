output "elb-address" {
  value = "${aws_elb.web.dns_name}"
}
