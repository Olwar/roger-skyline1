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
		
		
