#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# SetFunctions.sh: Functions to set up all collected data from loaded answer file.
# Site           : https://github.com/tiagotarifa/pocinstaller
# Author         : Tiago Tarifa Munhoz
# License        : GPL
#
#--------/ Description /--------------------------------------------------------
# These functions set all data collected like hostname, locales, keyboard layout
# 
# 
# 
#
#--------/ Important Remarks /--------------------------------------------------
#     To best view this code use Vim with this configuration settings:
#  execute pathogen#infect() #optional
#  set nocompatible
#  filetype plugin indent on
#  set foldenable
#  set foldmethod=marker
#  au FileType sh let g:sh_fold_enabled=5
#  au FileType sh let g:is_bash=1
#  au FileType sh set foldmethod=syntax
#  syntax on
#  let g:gruvbox_italic=1	#optional
#  colorscheme gruvbox		#optional
#  set background=light
#  set number
#  set tabstop=4 
#  set softtabstop=0 
#  set noexpandtab
#  set shiftwidth=4
#  set foldcolumn=2
#  set autoindent
#  set showmode
#
#    or you can use Kate software: https://kate-editor.org/
#
#--------/ Thanks /-------------------------------------------------------------
# Brazilian shell script yahoo list: shell-script@yahoogrupos.com.br
#   Especially: Julio (below), Itamar (funcoeszz co-author: http://funcoeszz.net)
#	and other 4K users who make this list rocks!
# The brazilian shell script (pope|master) Julio Cezar Neves who made the best
#   portuguese book of shell script (Programação Shell Linux 11ª edição);
#	His page: http://wiki.softwarelivre.org/TWikiBar/WebHome
# Hartmut Buhrmester: Ho rewrite wsusoffline script for Linux. I I was inspired 
#   by the way you did your log, and copy some code too.
# Cidinha (my wife): For her patience and love.
# 
#--------/ History /------------------------------------------------------------
#  Legend: '-' for features and '+' for corrections
#    Version: 1.0 released in 2017-07-09
#     -Support to colors (see dialog's man);
#     -Only show help line(--hline) if is need it;
#     -Detect if lists has 2 or 3 itens and handle with that;
#     -Handle with terminal size (lines and columms);
#    TODO:
#     -Finish GuiIntro function;
#     -Add translate support;
#--------/ /-------------------------------------
SetDHCP(){ #Use: SetDHCP <enpXsX|wlpXsX|or any name for this device>
	local device="$1"
	local titleError="Error"
	local textError1="dhcpcd or dhclient not found! Try Fixed IP..."
	local textError2="Could not set DHCP address for $device! Try Fixed IP..."
	local titleSuccess="DHCP"
	local textSuccess="DHCP returns this ip address for $device"
	local ip
	local dhcpReleaseCommand="$(type -p dhcpcd) -k" \
		|| local dhcpReleaseCommand="$(type -p dhclient) -r"
	if [ -z "${dhcpReleaseCommand%-*}" ]
	then
		GuiMessage "$titleError" "$textError" || return
		return 1
	else
		eval $dhcpReleaseCommand $device
		local dhcpCommand="${dhcpReleaseCommand%-*}"
	fi
	eval $dhcpCommand $device
	if [ $? -eq 0 ]
	then
		ip="$(ip addr show $device \
			| grep -Eo -m1 '([12]?[0-9]?[0-9])(\.[12]?[0-9]?[0-9]){3}/(8|16|24)')"
		GuiMessageBox "$titleSuccess" "$textSuccess\nIP: $ip\n" || return
	else
		GuiMessageBox "$titleError" "$textError2" || return
		LogMaker "WAR" "Network: Impossíble to get IP from dhcp server!" > /dev/null
		return 1
	fi
	LogMaker "LOG" "Network: Set '$ip' on '$device'."
}
SetFixedIP() { #Use: SetFixedIP <enp1s3|wlp3s0b1>
	local device="$1"
	local step=IP
	local ip gateway dns 
	while :
	do
		case $step in
			IP)
				ip=''
				ip="$(GuiInputBox "Set IP" "Type ip/mask Example: 192.168.15.10/16")" \
					|| return 1
				if ip="$(grep -Eo '([12]?[0-9]?[0-9])(\.[12]?[0-9]?[0-9]){3}/(8|16|24)' <<<"$ip")"
				then
					step=Gateway
				else
					GuiMessageBox "Error" "It's a not valid IP address. Try again" || return
				fi
				;;
	   Gateway)
				gateway=''
				gateway="$(GuiInputBox "Set Gateway" "Type gateway address Example: 192.168.15.1")" \
					|| step=IP
				if gateway="$(grep -Eo '([12]?[0-9]?[0-9])(\.[12]?[0-9]?[0-9]){3}' <<<"$gateway")"
				then
					step=DNS
				else
					GuiMessageBox "Error" "It's a not valid IP address. Try again" || return
				fi
				;;
		   DNS)
				dns=''
				dns="$(GuiInputBox "Set DNS" "Type DNS address Example: 8.8.8.8")" \
					|| step=Gateway
				if dns="$(grep -Eo '([12]?[0-9]?[0-9])(\.[12]?[0-9]?[0-9]){3}' <<<"$dns")"
				then
					break
				else
					GuiMessageBox "Error" "It's a not valid IP address. Try again" || return
				fi
				;;
		esac
	done
	echo ip addr flush dev $device
	echo ip addr add $ip dev $device
	echo ip route add default via $gateway dev $device
	echo "nameserver $dns" > /tmp/resolv.conf
	#if ping -c1 $gateway
	if [ -d /tmp ]
	then
		GuiMessageBox "Congratulations" "Your lan is configured:\nIP:$ip\nGateway:$gateway\nDNS:$dns"
	else
		GuiMessageBox "Error" "I can't communicate with your gateway ($gateway)!\nCheck you lan configuration"
		return 1
	fi
}
SetEthernet() { #Use: SetEthernet ethernetDeviceName
	local device="$1"
	local title="Ethernet"
	local text="Select a way to set up '$device'"
	local choice="$(GuiMenu "$title" "$text" 'DHCP Fixed_Address')" || return
	case $choice in
				 DHCP) SetDHCP "$device"	;;
		Fixed_Address) SetFixedIP "$device"	;;
	esac
}
SetWireless() { #Use: SetWireless wirelessDeviceName
	local device="$1"
	local title="Wireless"
	local wpaConfig="/etc/wpa_supplicant/${device}.conf"
	local gb1 gb2 gb3 quality wifi wifiList wifiSelected networkID wifiPassword

	echo -e "ctrl_interface=/run/wpa_supplicant\nupdate_config=1" > "$wpaConfig"
	if wpa_supplicant -B -i $device -c $wpaConfig
	then
		while :
		do
			wifiList=''
			wpa_cli scan > /dev/null 2>&1
			while read gb1 gb2 quality gb3 wifi
			do
				wifiList="$wifiList $wifi ${quality#-} off"
			done < <(wpa_cli scan_results | grep -E '^[[:alnum:]][[:alnum:]]:')
		done
		wifiSelected="$(GuiRadiolist "$title" "Select a wireless lan" "$wifiList")" \
			|| return 1
	else
		local textError="wpa_supplicant gave a error when it's tried to start."
		GuiMessageBox "Error" "$textError" \
			|| return 1
	fi
	wifiPassword="$(GuiPasswordBox "$title" "Input a password for '$wifiSelected'")"
	networkID="$(wpa_cli -i "$device" add_network)"
	wpa_cli -i "$device" set_network $networkID ssid \"$wifiSelected\"
	wpa_cli -i "$device" set_network $networkID psk \"$wifiPassword\"
	wpa_cli -i "$device" enable_network $networkID
	wpa_cli -i "$device" save_config
	SetDHCP "$device"
}
SetNetworkConfiguration(){ #Set up the network for installation | Use: --text-mode in automatic install
	local title="Network"
	local text="Configure your network for installation"
	local ethernetDevice="$(GetEthernetDevice)"
	local wifiDevice="$(GetWifiDevice)"
	local siteToPing="www.google.com.br"
	local textMode="$1"
	local choice

	if ping -c1 "$siteToPing" > /dev/null 2>&1 
	then
		return 0
	else
		if [ -n "$textMode" ] 
		then 
			LogMaker "MSG" "Network: There is no internet conection. Trying to install without it..."
			WaitingNineSeconds
			return 0
		else
		LogMaker "LOG" "Network: There is no internet conection. Trying to configure network..."
		fi

		if GuiYesNo "$title" "There is no network connection.
			Do you want to configure lan?"
		then
			choice="$(GuiMenu "$title" "$text" "Ethernet Wireless")"
			case $choice in
				Ethernet) SetEthernet "$ethernetDevice" ;;
				Wireless) SetWireless "$wifiDevice" ;;
			esac 
		else
			GuiMessageBox "$title" "There is no internet connection, but I'll leave you alone."
			return 1
		fi
	fi
}
SetDateAndTime(){ #Set up date and time automatic(internet) or manual
	local title="Date and Time"
	local text="Your system's date and time could not be set automatically.\n
		Manually set it"
	local siteToPing="www.google.com.br"
	local textMode="$1"
	local date time

	if ping -c1 "$siteToPing" > /dev/null 2>&1 
	then
		timedatectl set-ntp true
	else
		if [ -n "$textMode" ] 
		then 
			LogMaker "MSG" "DateAndTime: Impossible to automatic update the system clock!"
			WaitingNineSeconds
			return 0
		else
			LogMaker "LOG" "DateAndTime: Impossible to automatic update the system clock!"
		fi
		date="$(GuiCalendar "$title" "$text")" || return
		time="$(GuiTimeBox "$title" "$text")"  || return
		date "${date%_*}${time}${date#*_}"	   || return
		hwclock -w							   || return
		LogMaker "LOG" "DateAndTime: date and time manualy defined!"
	fi
}
SetScriptToRunOnFirstBoot(){
	local script="$1"
	if [ -n "$packages" ]
	then
		LogMaker "MSG" "$logStep Downloading all packages to install on first boot"
		arch-chroot $dirTarget pacman -Syw --noconfirm $packages \
			&& LogMaker "MSG" "$logStep Downloaded additional packages." \
			|| LogMaker "WAR" "$logStep Impossible to download additional packages."
	fi
	cat >>$fileSystemdUnit <<-_eof_
		[Unit]
		Description=POC installer finishing installation

		[Service]
		Type=oneshot
		ExecStart=$fileFirstBootScript

		[Install]
		WantedBy=multi-user.target
	_eof_
	arch-chroot $dirTarget systemctl enable ${fileSystemdUnit#$dirTarget} \
		&& LogMaker "MSG" "$logStep '$fileFirstBootScript' will run on first boot." \
		|| LogMaker "ERR" "$logStep Impossible to enable '$fileFirstBootScript' to run on first boot."
}
SetGrubOnTarget(){
	local dirBoot="$DirBoot"
	local diskBoot="$1"
	local grubArgs="$2"
	LogMaker "MSG" "$logStep Installing grub..."
	eval arch-chroot $dirTarget grub-install $grubArgs $diskBoot\
		&& LogMaker "MSG" "$logStep Grub installed with arguments '$grubArgs'" \
		|| LogMaker "ERR" "$logStep Impossible to install grub! Grub arguments was '$grubArgs'"
	eval arch-chroot $dirTarget grub-mkconfig -o "$dirBoot/grub/grub.cfg" \
		&& LogMaker "MSG" "$logStep 'grub.cfg' created on '$dirBoot/grub/grub.cfg'" \
		|| LogMaker "ERR" "$logStep Impossible to create '$dirBoot/grub/grub.cfg'"

	if IsEfi 
	then 
		#Workaround for some motherboards
		#Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader
		(
		mkdir -p $dirBoot/efi/efi/boot
		cp $dirBoot/efi/efi/arch/grubx64.efi $dirBoot/efi/efi/boot/bootx64.efi
		) \
			&& LogMaker "MSG" "$logStep Workaround made for EFI bios" \
			|| LogMaker "WAR" "$logStep Impossible to make a workaround for EFI bios"
	fi
}
