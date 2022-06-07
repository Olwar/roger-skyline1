#!/bin/sh

echo "copying the website..."
scp -P 50000 index.nginx-debian.html oairola@10.11.247.17:/var/www/html/
sleep 2

echo "restarting the remote server..."
ssh -t -p 50000 oairola@10.11.247.17 "sudo systemctl restart nginx"

echo "done."
