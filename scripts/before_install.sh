#!/bin/bash

yum update -y
yum upgrade -y

# install dependencies
yum install mercurial git gcc libc6-dev go -y

service nginx stop
service nginx start

# install golang
cd /home/ec2-user
