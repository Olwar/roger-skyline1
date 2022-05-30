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
