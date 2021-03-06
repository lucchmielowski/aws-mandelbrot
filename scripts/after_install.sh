#!/bin/bash

# make golang workspace
cd $HOME
mkdir gocode
echo "export GOPATH=$HOME/gocode" >> $HOME/.bashrc
echo "export PATH=$PATH:$GOPATH/bin" >> $HOME/.bashrc
export GOPATH=$HOME/gocode
export PATH=$PATH:$GOPATH/bin


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
