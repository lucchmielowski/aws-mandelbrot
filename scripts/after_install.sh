#!/bin/bash

# Nginx conf
sudo ln -s /etc/nginx/sites-available/mandelbrot /etc/nginx/sites-enabled/mandelbrot
sudo rm /etc/nginx/sites-enabled/default
sudo service nginx restart

# make golang workspace
cd $HOME
mkdir gocode
echo "export GOPATH=$HOME/gocode" >> $HOME/.bashrc
echo "export PATH=$PATH:$GOPATH/bin" >> $HOME/.bashrc

# activate changes
source $HOME/.bashrc

# install golang dependency management tool
go get github.com/tools/godep

# go to golang app
cd $GOPATH/src/github.com/lucchmielowski/aws-mandelbrot/

# restore dependencies
godep restore

# make binary
go install
