#!/bin/bash

# usually sudo but not needed because appspec.yml has runas root
systemctl enable aws-mandelbrot
systemctl start aws-mandelbrot
service nginx restart
