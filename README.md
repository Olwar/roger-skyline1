# roger-skyline1
 Configuring a web server on Virtual Machine

1. You must create a non-root user to connect to the machine and work.
	login as root
	
		su

	install sudo and vim
	
		apt update -y
		apt upgrade -y
		apt install sudo -y
		apt install vim -y
		
	edit sudoers file
	
		cd /etc
		chmod +w sudoers
		vim sudoers
		
	add line after root to look like the root line:
	
		user ALL=(ALL:ALL) ALL
		chmod -w sudoers
		
	exit root:
	
		exit

2. configuring a static IP and a Netmask in \30 because you don't want to use DHCP service of your machine (DHCP assigns ip-addresses but we want to do it our selves).
	change the VM adapter setting from NAT to Bridged Adapter on VirtualBox or whatever hypervisor you're using.
	modify your /etc/network/interface -file, to add your network interface device:
	
		# The primary network interface
		auto enp0s3
		
	then add a file in your interfaces.d
	
		sudo vim /etc/network/interfaces.d/enp0s3
		
	add the lines, replaces the X's with numbers up to 255:
	
		iface enp0s3 inet static
   		address 10.11.XXX.XXX (the static IP address you want)
    		netmask 255.255.255.252 (netmask = Netmasks (or subnet masks) are a shorthand for referring to ranges of consecutive IP addresses
					so you can also use certain range of ip addresses. For example one computer room might have ip addresses only 						certain range)
		gateway 10.11.254.254 (gateway = all data passes through this)
		
	restart your network service to get changes come into effect:
	
		sudo service networking restart
		
	check that network is running and ip address has been changed:
	
		sudo service networking status
		sudo ifconfig
		
	ping something to see your network works:
	
		ping seraphinabot.dev
		
3. configuring SSH

	install net-tools
	
		sudo apt install vim net-tools -y
	
	copy your host machine public SSH key to the VM:
	
		ssh-copy-id -i [path to public key] [username]@[static ip of vm] -p [ssh port of vm]
	
	Let's modify /etc/ssh/sshd_config (change perms before and after):
	
		Port <port that is not in use> #(can be checked with cat /etc/services)
		PasswordAuthentication no
		PubkeyAuthentication yes
		PermitRootLogin no
		
	then restart sshd for the effects to come into action:
	
		sudo service sshd restart
	
4. configuring firewall
	Let's install easy-to-use firewall ufw (uncomplicated firewall)
	
		sudo apt install ufw
	
	then deny all incoming connections and allow all outgoing connection so we can specifically only allow the ones we want:
	
		sudo ufw default deny incoming
		sudo ufw default allow outgoing
	
	we will allow SSH, HTTP and HTTPS (so we can connect to the VM and the internet works)
	
		sudo ufw allow 50000/tcp
		sudo ufw allow 80/tcp
		sudo ufw allow 443/tcp
		
	tcp enables application programs and computing devices to exchange messages over a network. It is designed to send packets across the internet and ensure the successful delivery of data and messages over networks.
	
	then we will enable the firewall and see if it's working:
	
		sudo ufw enable
		sudo ufw status
		
5. DOS protection
	Install fail2ban. Fail2ban is an intrusion prevention software framework that protects computer servers from brute-force attacks.
	
		sudo apt install fail2ban
	
	then we will copy configuration file jail.conf in /etc/fail2ban
	
		sudo cp jail.conf jail.local
		
	why do we do this? Every .conf file can be overridden with a file named .local. The .conf file is read first, then .local, with later 			settings overriding earlier ones. Thus, a .local file doesn't have to include everything in the corresponding .conf file, only those 			settings that you wish to override. Modifications should take place in the .local and not in the .conf. This avoids merging problem 			when upgrading. These files are well documented and detailed information should be available there.
	
	then edit the jail.local:
	
		#
		# SSH servers
		#

		[sshd]

		# To use more aggressive sshd modes set filter parameter "mode" in jail.local:
		# normal (default), ddos, extra or aggressive (combines all).
		# See "tests/files/logs/sshd" or "filter.d/sshd.conf" for usage example and details.
		mode   = agressive
		enabled = true
		port    = ssh
		logpath = %(sshd_log)s
		backend = %(sshd_backend)s
		maxentry = 3
		bantime = 600
	
	and the HTTP and HTTPS:
	
		# Protect HTTP and HTTPS (HTTP)

		[http-get-dos]

		enabled = true
		port = http,https
		filter = http-get-dos
		logpath = /var/log/apache2/access.log
		maxentry = 300
		findtime = 300
		bantime = 600
		action = iptables[name=HTTP, port=http, protocol=tcp]
	
	then we actually need to define that filter http-get-dos that we just specified. We can do this in a file /etc/fail2ban/filter.d/http-get-dos.conf. Create it.
	
	Add this in there:
	
		[Definition]

		failregex = ^<HOST> -.*"GET.*
		ignoreregex =
	
	this will just make sure that we actually ban every ip that tries to connect too often.
	test your protection with https://github.com/gkbrk/slowloris
	
6. Port scan protection

	Let's install psad. psad is a collection of three lightweight system daemons (two main daemons and one helper daemon) that run on Linux 	machines and analyze iptables log messages to detect port scans and other suspicious traffic. A daemon = a service process that runs in the 		background and supervises the system or provides functionality to other processes.
	
		`sudo apt install psad`
	
	configure psad by editing /etc/psad/psad.conf :
	
		EMAIL_ADDRESSES			root@debian.lan; #email to notify, will be configured later
		HOSTNAME			debian;
		PORT_RANGE_SCAN_THRESHOLD	1; #how many ports minimum must be scanned for an alert
		IPT_SYSLOG_FILE			/var/log/syslog; #where psad looks for active logs
		MIN_DANGER_LEVEL		1; #what level should be reached for an email to be sent
		ENABLE_AUTO_IDS			Y; #if this is Y, psad can automatically configure your firewall to block certain addresses
		AUTO_IDS_DANGER_LEVEL		1; #what danger level is reached for an ip to be banned
		AUTO_BLOCK_TIMEOUT		300; #how long is the ban
	
	then restart psad:
	
		sudo service psad restart

7. Stopping unneeded services

	scan all enabled services:
	
		`sudo systemctl list-unit-files --type=service --state=enabled --all`
	
	for this project we need:
	
		apache2
		cron
		fail2ban
		getty
		networking
		ssh
		ufw
	
	stopping unnecessary services:
	
		sudo systemctl disable [service name]
	
8. Package update script

	do a script in /user/local/bin (change the permissions before and after)
	this is what i put there:
	
		#!/bin/sh
		echo "[`date`] sudo apt update -y" >> /var/log/update_script.log
		echo "`sudo apt update -y`" >> /var/log/update_script.log
		echo "[`date`] sudo apt upgrade -y" >> /var/log/update_script.log
		echo "`sudo apt upgrade -y`" >> /var/log/update_script.log
	
	then let's add a scheduling task in your crontab file:
	
		`sudo vim /etc/crontab`
	
	and add the lines:
	
		@reboot		root sh /usr/local/bin/package_update.sh &
		0 4 * * 1 	root sh /usr/local/bin/package_update.sh &

9. Make a script to monitor changes of the /etc/crontab file and sends an email to
root if it has been modified. Create a scheduled script task every day at midnight.

	Make the script in /usr/local/bin/

		#!/bin/sh

		CRONTAB=/etc/crontab
		BACKUP=/var/spool/cron/crontabs/backup

		echo 'checking if changes in crontab...'

		if [ ! -e $BACKUP ]
		then
			echo 'backuping crontab...'
			cp $CRONTAB $BACKUP
		fi

		DIFF=$(diff $CRONTAB $BACKUP)

		if [ $? -eq 0 ]
		then
			:
		else
			echo "crontab's been changed" | mail -s "crontab change" root@debian.lan
		fi

		cp $CRONTAB $BACKUP
	
	edit your /etc/crontab to schedule the task:

		0 0 * * * sh /usr/local/bin/monitor_crontab.sh &
		
	install mailutils and postfix to configure e-mail:
		`sudo apt install mailutils postfix`
	in postfix installation choose local only and set the system mail name to debian.lan
	
	change root: to root: root@debian.lan in /etc/aliases and run `sudo newaliases` for the effects to come into effect.
	when logged in as root, you can do `mailx` to see the e-mails
	
	
Then to the web part!

	You have to set a web server who should BE available on the VM’s IP or an host
	(init.login.com for exemple). About the packages of your web server, you can choose
	between Nginx and Apache. You have to set a self-signed SSL on all of your services.
	You have to set a web "application" from those choices:
	• A login page.
	• A display site.
	• A wonderful website that blow our minds.
	The web-app COULD be written with any language you want

	Okay so, for this we can choose between nginx or apache. I'm gonna choose nginx and follow this guide https://medium.com/adrixus/beginners-guide-to-nginx-configuration-files-527fcd6d5efd:
	
		sudo apt-get update
		sudo apt-get install nginx
	
	nginx puts a default website in /var/www/html and you can replace that with your own html file.
	
eval form says that nginx can't listen to the localhost. 
	So let's se change in /etc/nginx/sites-enables the listen [::]:80 to <your-static-ip>:80 e.g. 10.11.247.17:80 and remove listen 80 default_server;
	
Allright then we will create a self-signed SSL certificate
	
I used this guide: https://www.digitalocean.com/community/tutorials/how-to-create-a-self-signed-ssl-certificate-for-nginx-on-debian-10

TLS, or transport layer security, and its predecessor SSL, which stands for secure sockets layer, are web protocols used to wrap normal traffic in a protected, encrypted wrapper. Using this technology, servers can send traffic safely between the server and clients without the possibility of the messages being intercepted by outside parties.
	
Creating an SSL certificate and key -pair can be done in one line.

	sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt


	openssl: This is the basic command line tool for creating and managing OpenSSL certificates, keys, and other files.
	req: This subcommand specifies that we want to use X.509 certificate signing request (CSR) management. The “X.509” is a public key 			infrastructure standard that SSL and TLS adheres to for its key and certificate management. We want to create a new X.509 cert, so 			we are using this subcommand.
	-x509: This further modifies the previous subcommand by telling the utility that we want to make a self-signed certificate instead of 			generating a certificate signing request, as would normally happen.
	-nodes: This tells OpenSSL to skip the option to secure our certificate with a passphrase. We need Nginx to be able to read the file 			without user intervention when the server starts up. A passphrase would prevent this from happening because we would have to enter 			it after every restart.
	-days 365: This option sets the length of time that the certificate will be considered valid. We set it for one year here.
	
	-newkey rsa:2048: This specifies that we want to generate a new certificate and a new key at the same time. We did not create the key 			that is required to sign the certificate in a previous step, so we need to create it along with the certificate. The rsa:2048 portion 			tells it to make an RSA key that is 2048 bits long.
	-keyout: This line tells OpenSSL where to place the generated private key file that we are creating.
	-out: This tells OpenSSL where to place the certificate that we are creating.
	
	
Fill out the prompts appropriately. The most important line is the one that requests the Common Name (e.g. server FQDN or YOUR name). You need to enter the domain name associated with your server or your server’s public IP address.

then we are going to add "forward secrecy". Forward secrecy protects past sessions against future compromises of keys or passwords. By generating a unique session key for every session a user initiates, the compromise of a single session key will not affect any data other than that exchanged in the specific session protected by that particular key.
		
		sudo openssl dhparam -out /etc/nginx/dhparam.pem 4096
	
then we need to configure Nginx to use SSL
	
Let's create a new configuration Nginx snippet to tell Nginx where SSL certificate and key are

		sudo vim /etc/nginx/snippets/self-signed.conf
		
add this there:
	
		ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;
		ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;
	
Then we will enhance our SSL's security with another conf snippet
	
		sudo vim /etc/nginx/snippets/ssl-params.conf
	
copy this there:
	
		ssl_protocols TLSv1.2;
		ssl_prefer_server_ciphers on;
		ssl_dhparam /etc/nginx/dhparam.pem;
		ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-			AES256-SHA384;
		ssl_ecdh_curve secp384r1; # Requires nginx >= 1.1.0
		ssl_session_timeout  10m;
		ssl_session_cache shared:SSL:10m;
		ssl_session_tickets off; # Requires nginx >= 1.5.9
		ssl_stapling on; # Requires nginx >= 1.3.7
		ssl_stapling_verify on; # Requires nginx => 1.3.7
		resolver 8.8.8.8 8.8.4.4 valid=300s;
		resolver_timeout 5s;
		# Disable strict transport security for now. You can uncomment the following
		# line if you understand the implications.
		# add_header Strict-Transport-Security "max-age=63072000; includeSubDomains; preload";
		add_header X-Frame-Options DENY;
		add_header X-Content-Type-Options nosniff;
		add_header X-XSS-Protection "1; mode=block";
	
for DNS resolver for upstream requests we chose Google's ip. Meaning that if somebody wants to see what's "after" our server, it gets redirected to google.
the lines commented out protects from certain attacks but narrows usability.
	
Now let's enable SSL in Nginx
	
	backup your default nginx-conf `sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak`
	
we will modify that default file. We will modify the existing server block to serve SSL traffic on port 443, and then create a new server block to respond on port 80 and automatically redirect traffic to port 443.
	
so change listen <your-static-ip>:80 default_server; to
	
		listen 10.11.247.17:443 ssl;
	   	include snippets/self-signed.conf;
  		include snippets/ssl-params.conf;
	
then add another block after the closing }
	
		server {
		    listen <your-static-ip>:80;

		    server_name _;

		    return 302 https://10.11.247.17;
		}
	
this redirects the traffic from port 80 to HTTPS.
	
next we will adjust the firewall to allow SSL traffic:
	
		sudo ufw allow 'Nginx Full'
	
then run `sudo nginx -t` to see that you have correct syntax in your nginx -files. this is what you should see:
	
		nginx: [warn] "ssl_stapling" ignored, issuer certificate not found for certificate "/etc/ssl/certs/nginx-selfsigned.crt"
		nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
		nginx: configuration file /etc/nginx/nginx.conf test is successful
	
	restart nginx `sudo systemctl restart nginx`
	
then finally if everything is good change the 302 to 301 in the /etc/nginx/sites-available/default, this makes the redirect permanent.
	
All right people, it's time for the final stage which is deployment automation. For this I will create a simple script.
	
		You can see it in deploy.sh
