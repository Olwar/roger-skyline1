#!/bin/sh

echo "copying the website..."
scp -P 50000 index.nginx-debian.html oairola@10.11.248.17:/home/oairola
sleep 2

ssh -t -p 50000 oairola@10.11.248.17 "sudo mv /home/oairola/index.nginx-debian.html /var/www/html"

echo "restarting the remote server..."
ssh -t -p 50000 oairola@10.11.248.17 "sudo systemctl restart nginx"

echo "done."
