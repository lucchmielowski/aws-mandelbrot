#!/bin/bash
apt-get -y update
apt-get -y install awscli
apt-get -y install ruby
cd /home/ubuntu
aws s3 cp s3://aws-codedeploy-eu-west-1/latest/install . --region eu-west-1
chmod +x ./install
./install auto
