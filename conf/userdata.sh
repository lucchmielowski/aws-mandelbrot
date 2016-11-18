#!/bin/bash -v

#install dependencies
sudo apt-get update -y
sudo apt-get install -y build-essential nginx golang git

# Create nginx configuration
sudo bash -c "curl https://gist.githubusercontent.com/lucchmielowski/b51e41cdd186ef30824d40444d907af1/raw/f81c348ad1689da0e4df0fc41191a2ff75fb71bb/site-available-default > /etc/nginx/sites-available/default"
sudo service nginx restart

# Configure go app
cd /root
mkdir go
export GOPATH=/root/go
go get github.com/lucchmielowski/aws-mandelbrot
cd /root/go/src/github.com/lucchmielowski/aws-mandelbrot
go build

# Create the app service which will run in background
sudo bash -c "curl https://gist.githubusercontent.com/lucchmielowski/b51e41cdd186ef30824d40444d907af1/raw/0b8c3c8c8dc19641b6c6a33d7b40833dc634f454/aws-mandelbrot.service > /etc/systemd/system/aws-mandelbrot.service"
sudo systemctl enable aws-mandelbrot
sudo systemctl start aws-mandelbrot
