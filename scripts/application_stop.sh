[Unit]
Description=Golang mandelbrot app

[Service]
ExecStart=/bin/bash -c 'sudo /root/aws-mandelbrot/aws-mandelbrot'

[Install]
WantedBy=multi-user.target
