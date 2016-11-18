#!/bin/bash

yum update -y
yum upgrade -y

# install dependencies
yum install mercurial git gcc libc6-dev nginx go -y

# install golang
cd /home/ec2-user
