
#!/bin/bash
sudo apt-add-repository ppa:ubuntu-lxc/lxd-stable
apt-get update -y
apt-get upgrade -y

# install dependencies
apt-get install mercurial git gcc libc6-dev nginx golang -y

# Nginx conf
ln -s /etc/nginx/sites-available/mandelbrot /etc/nginx/sites-enabled/mandelbrot
rm /etc/nginx/sites-enabled/default
service nginx restart
