# roger-skyline1
 Configuring a web server on Virtual Machine

1. You must create a non-root user to connect to the machine and work.

		**login as root**
		su

		**install sudo and vim**
		apt update -y
		apt upgrade -y
		apt install sudo -y
		apt install vim -y
		
		**edit sudoers file**
		cd /etc
		chmod +w sudoers
		vim sudoers
		
		add line after root to look like the root line:
		user ALL=(ALL:ALL) ALL
		chmod -w sudoers
		
		exit root:
		exit

2. configuring a static IP and a Netmask in \30 because you don't want to use DHCP service of your machine (DHCP assigns ip-addresses but we want to do it our selves).
		
		**change the VM adapter setting from NAT to Bridged Adapter on VirtualBox or whatever hypervisor you're using.**
		modify your /etc/network/interface -file, to add your network interface device:
		# The primary network interface
		auto enp0s3
		then add a file in your interfaces.d
		chmod o+w interfaces.d
		cd interfaces
		vim enp0s3
		
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
		Let's modify /etc/ssh/sshd_config (change perms before and after):
		Port <port that is not in use> (can be checked with cat /etc/services)
		PasswordAuthentication no
		PubkeyAuthentication yes
		PermitRootLogin no
		
		then restart sshd for the effects to come into action:
		sudo service sshd restart
	
		then copy your host machine public SSH key to the VM:
		ssh-copy-id -i [path to public key] [username]@[static ip of vm] -p [ssh port of vm]
	
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
		
		tcp enables application programs and computing devices to exchange messages over a network. It is designed to send packets across the 			internet and ensure the successful delivery of data and messages over networks.
	
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
	
		then we actually need to define that filter http-get-dos that we just specified. We can do this in a file /etc/fail2ban/filter.d/http-			get-dos.conf. Create it.
		Add this in there:
		[Definition]

		failregex = ^<HOST> -.*"GET.*
		ignoreregex =
	
		this will just make sure that we actually ban every ip that tries to connect too often.
		test your protection with https://github.com/gkbrk/slowloris
	
6. Port scan protection
		Let's install psad. psad is a collection of three lightweight system daemons (two main daemons and one helper daemon) that run on Linux 		machines and analyze iptables log messages to detect port scans and other suspicious traffic. A daemon = a service process that runs in 		the background and supervises the system or provides functionality to other processes.
		`sudo apt install psad`
	
		configure psad by editing /etc/psad/psad.conf :
		EMAIL_ADDRESSES			root@debian.lan; #email to notify
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
	
8. 
