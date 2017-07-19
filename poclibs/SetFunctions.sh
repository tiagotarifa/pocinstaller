#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# SetFunctions.sh: Functions to set up any configuration needed.
#                  It's part of Piece of Cake Installer
# Site           : https://github.com/tiagotarifa/pocinstaller
# Author         : Tiago Tarifa Munhoz
# License        : GPL3
#
#--------/ Description /--------------------------------------------------------
#   It's just a 'set functions' helper for pocinstaller.sh. It's set up any 
# configuration needed for system installation (livecd) or target system.
#   All these functions has a little description who explain how it works.
# I.e. SetDateAndTime(){ #Set up date and time automatic(internet) or manual
#      SetDHCP(){ #Use: SetDHCP <networkDevice> 
#
#--------/ Important Remarks /--------------------------------------------------
#  To best view this code use Vim with this configuration settings (~/.vimrc):
#		  execute pathogen#infect() #optional
#		  set nocompatible
#		  filetype plugin indent on
#		  set foldenable
#		  set foldmethod=marker
#		  au FileType sh let g:sh_fold_enabled=5
#		  au FileType sh let g:is_bash=1
#		  au FileType sh set foldmethod=syntax
#		  syntax on
#		  let g:gruvbox_italic=1	#optional
#		  colorscheme gruvbox		#optional
#		  set background=light
#		  set number
#		  set tabstop=4 
#		  set softtabstop=0 
#		  set noexpandtab
#		  set shiftwidth=4
#		  set foldcolumn=2
#		  set autoindent
#		  set showmode
#  or you can use Kate software: https://kate-editor.org/
#
#--------/ Thanks /-------------------------------------------------------------
# -Brazilian shell script yahoo list: shell-script@yahoogrupos.com.br
#   Especially: Julio (below), Itamar (funcoeszz co-author: http://funcoeszz.net)
#	and other 4K users who make this list rocks!
# -The brazilian shell script (pope|master) Julio Cezar Neves who made the best
#   portuguese book of shell script (Programação Shell Linux 11ª edição);
#	His page: http://wiki.softwarelivre.org/TWikiBar/WebHome
# -Hartmut Buhrmester: Ho rewrite wsusoffline script for Linux. I I was inspired 
#   by the way you did your log, and copy some code too.
# -Cidinha (my wife): For her patience and love.
# 
#--------/ History /------------------------------------------------------------
# Legend: '-' for features and '+' for corrections
#  Version: 1.0 released in 2017-07-19
#   -Network functions to fix IP and DHCP;
#   -Set up grub according by system I.e: Efi(x86_64) or bios(x86)
#   ...Many small others
#--------/ Network functions /--------------------------------------------------
SetDHCP(){ #Use: SetDHCP <enpXsX|wlpXsX|or any name for this device>
	local device="$1"
	local titleError="Error"
	local textError1="dhcpcd or dhclient not found! Try Fixed IP..."
	local textError2="Could not set DHCP address for $device! Try Fixed IP..."
	local titleSuccess="DHCP"
	local textSuccess="DHCP returns this ip address for $device"
	local ip count
	local dhcpCommand="$(type -p dhcpcd)" \
		|| local dhcpCommand="$(type -p dhclient)"
	if [ -z "$dhcpCommand" ]
	then
		GuiMessage "$titleError" "$textError" || return
		return 1
	fi
	for ((count=0;count<4;count++))
	do
		if $dhcpCommand $device
		then
			ip="$(ip addr show $device \
				| grep -Eo -m1 '([12]?[0-9]?[0-9])(\.[12]?[0-9]?[0-9]){3}/(8|16|24)')"
			GuiMessageBox "$titleSuccess" "$textSuccess\nIP: $ip\n" 
			break
		else
			GuiMessageBox "$titleError" "$textError2"
			LogMaker "WAR" "Network: Impossible to get IP from dhcp server!" > /dev/null
			return 1
		fi
	done
	LogMaker "LOG" "Network: Set '$ip' on '$device'."
}
SetFixedIP(){ #Use: SetFixedIP <enp1s3|wlp3s0b1>
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
	( ip addr flush dev $device
	ip addr add $ip dev $device
	ip route add default via $gateway dev $device 
	"nameserver $dns" > /etc/resolv.conf ) \
		&& LogMaker "LOG" "'$ip' on '$device' defined!" \
		|| LogMaker "ERR" "Impossible to set '$ip' on '$device'!"
	if ping -c1 $gateway
	then
		LogMaker "LOG" "Network comunication is ok!" 
		GuiMessageBox "Congratulations" "Your lan is configured:\nIP:$ip\nGateway:$gateway\nDNS:$dns"
	else
		LogMaker "WAR" "Impossible to comunicate with gateway!" 
		GuiMessageBox "Error" "I can't communicate with your gateway ($gateway)!\nCheck you lan configuration"
		return 1
	fi
}
SetEthernet(){ #Use: SetEthernet ethernetDeviceName
	local device="$1"
	local title="Ethernet"
	local text="Select a way to set up '$device'"
	local choice="$(GuiMenu "$title" "$text" 'DHCP Fixed_Address')" || return
	case $choice in
				 DHCP) SetDHCP "$device"	;;
		Fixed_Address) SetFixedIP "$device"	;;
	esac
}
SetWireless(){ #Use: SetWireless wirelessDeviceName
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
			if wpa_cli -i $device scan > /dev/null 2>&1
			then
				GuiTimer "Waiting" "Please wait while it trying to scan wireless networks" 5
				while read gb1 gb2 quality gb3 wifi
				do
					wifiList="$wifiList $wifi ${quality#-} off"
				done < <(wpa_cli -i $device scan_results | grep -E '^[[:alnum:]][[:alnum:]]:')
			fi
			if [ -z "$wifiList" ]
			then
				GuiYesNo "Error" "No Access point found. Do you want to try again?" \
					|| return 
			else
				wifiSelected="$(GuiRadiolist "$title" "Select a wireless lan" $wifiList)" \
					|| continue
				break
			fi
		done
	else
		local textError="wpa_supplicant gave a error when it's tried to start."
		GuiMessageBox "Error" "$textError" \
			|| return 1
	fi
	wifiPassword="$(GuiPasswordBox "$title" "Input a password for '$wifiSelected'")" \
		|| return 
	(
	networkID="$(wpa_cli -i "$device" add_network)"
	wpa_cli -i "$device" set_network $networkID ssid \"$wifiSelected\"
	wpa_cli -i "$device" set_network $networkID psk \"$wifiPassword\" 
	wpa_cli -i "$device" enable_network $networkID
	wpa_cli -i "$device" save_config
	) > /dev/null
	GuiTimer "Waiting" "Please wait wireless interface sync with access point" 5
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

	while :
	do
		[ -z "$textMode" ] && GuiTimer "Waiting" "Checking internet connection...Please wait" 0
		if ping -4 -c1 "$siteToPing" > /dev/null 2>&1 
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
				if GuiYesNo "$title" "There is no network connection. Do you want to configure lan?"
				then
					choice="$(GuiMenu "$title" "$text" "Ethernet Wireless")"
					case $choice in
						Ethernet) SetEthernet "$ethernetDevice" ;;
						Wireless) SetWireless "$wifiDevice" 	;;
					esac 
				else
					GuiMessageBox "$title" "There is no internet connection, but I'll leave you alone."
					return 1
				fi
			fi
	done
}
#--------/ Ordinary functions /-------------------------------------------------
SetDateAndTime(){ #Set up date and time automatic(internet) or manual
	local title="Date and Time"
	local text="Your system's date and time could not be set automatically.\n
		Manually set it"
	local siteToPing="www.google.com.br"
	local textMode="$1"
	local date time

	[ -z "$textMode" ] && GuiTimer "Waiting" "Checking internet connection...Please wait" 0
	if ping -4 -c1 "$siteToPing" > /dev/null 2>&1 
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
SetScriptToRunOnFirstBoot(){ #Use: /target/path /path/script/without/target/path
	local target="$1"
	local script="$2"
	local systemdGetty="$target/etc/systemd/system/getty@tty1.service.d/override.conf"
	local bashRoot="$target/root/.bash_profile"
	( 
	echo "/root/first_boot.sh" >> "$bashRoot" || return
	mkdir -m 755 -p "${systemdGetty%/*}"		|| return
	cat > "$systemdGetty" <<-_eof_
		[Service]
		ExecStart=
		ExecStart=-/usr/bin/agetty --autologin root --noclear %I \$TERM
	_eof_
	) && LogMaker "MSG" "$logStep '$script' will run on first boot." \
	  || LogMaker "ERR" "$logStep Impossible to enable '$script' to run on first boot."
}
SetGrubOnTarget(){ #Set up grub according to system. I.e: Efi(x86_64) or bios(x86)
	local dirTarget="$DirTarget"
	local dirBoot="$DirBoot"
	local partitionBoot="$(df --output=source "$dirBoot" 2>/dev/null | grep 'dev')"
	local diskBoot=${partitionBoot%[0-9]}
	local grubArgs="$1"
	LogMaker "MSG" "$logStep Installing grub..."
	eval arch-chroot $dirTarget grub-install $grubArgs $diskBoot\
		&& LogMaker "MSG" "$logStep Grub installed with arguments '$grubArgs $diskBoot'" \
		|| LogMaker "ERR" "$logStep Impossible to install grub! Grub arguments was '$grubArgs $diskBoot'"
	eval arch-chroot $dirTarget grub-mkconfig -o "/boot/grub/grub.cfg" \
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
SetLocales(){ #Use: SetLocales /target 's/^#en_US/en_US/'
	local target="$1"
	local locales="$2"
	local localeGen="$target/etc/locale.gen"
	sed -ri "$locales" $localeGen											\
		&& LogMaker "MSG" "$logStep Locales defined in $localeGen"			\
		|| LogMaker "ERR" "$logStep Impossible to set locales in $localeGen"
	arch-chroot $target locale-gen 											\
		&& LogMaker "MSG" "$logStep Locales generated" 						\
		|| LogMaker "ERR" "$logStep Impossible to generate locales"
}
SetRepositories(){ #Use: SetRepositories /target "$multilib" 's@^#http://repo@http://repo@'
	local target="$1"
	local multilib="$2"
	local repositories="$3"
	local fileMirrorlist="$target/etc/pacman.d/mirrorlist"
	local filePacmanConf="$target/etc/pacman.conf"
	sed -i 's/^S/#S/' $fileMirrorlist													\
		&& LogMaker "MSG" "$logStep Disable all repositories in $fileMirrorlist"		\
		|| LogMaker "ERR" "$logStep Impossible to disable all repositories in $fileMirrorlist"
	sed -i "$repositories" $fileMirrorlist												\
		&& LogMaker "MSG" "$logStep Repositories defined in $fileMirrorlist"			\
		|| LogMaker "ERR" "$logStep Impossible to set repositories in $fileMirrorlist"
	if [ "$multilib" == "yes" ]
	then
		sed -i '/^#\[multilib\]/,/#Include/ s/^#//' $filePacmanConf						\
			&& LogMaker "MSG" "$logStep Multilib support enabled in '$filePacmanConf'"	\
			|| LogMaker "ERR" "$logStep Impossible to enable multilib support in '$filePacmanConf'" 
	else
		LogMaker "MSG" "$logStep Multilib support has been disabled!"
	fi
}
SetLanguage(){ #Use: SetLanguage /target "pt_BR.UTF-8"
	local target="$1"
	local language="$2"
	local file="$target/etc/locale.conf"
	echo "LANG=$language" > $file										\
		&& LogMaker "MSG" "$logStep Language defined in $file"			\
		|| LogMaker "ERR" "$logStep Impossible to set language in $file"
}
SetKeymap(){ #Use: SetKeymap /target "br-abnt2"
	local target="$1"
	local keymap="$2"
	local file="$target/etc/vconsole.conf"
	echo "KEYMAP=$keymap" > $file												\
		&& LogMaker "MSG" "$logStep Keyboard layout defined in $file"			\
		|| LogMaker "ERR" "$logStep Impossible to set keyboard layout in $file"
}
SetHostname(){ #Use: SetHostname /target "hostname"
	local target="$1"
	local hostname="$2"
	local fileHostname="$target/etc/hostname"
	local fileHosts="$target/etc/hosts"
	echo "$hostname" > $fileHostname												\
		&& LogMaker "MSG" "$logStep Hostname defined in $fileHostname"				\
		|| LogMaker "ERR" "$logStep Impossible to set '$hostname' in $fileHostname"
	echo -e "127.0.0.1\t${hostname}.localdomain\t$hostname" >> $fileHosts			\
		&& LogMaker "MSG" "$logStep Local DNS defined in $fileHosts"				\
		|| LogMaker "ERR" "$logStep Impossible to set local DNS in $fileHosts"
}
SetMkinitcpioHooks(){ #Use: SetMkinitcpioHooks /target 
	local target="$1"
	local fileMkinitcpioConf="$target/etc/mkinitcpio.conf"
	local hooks
	if [ "$(pvs | wc -l)" -gt 1 ] 
	then
		hooks="/^HOOKS=/ s/block/block lvm2/;"
		LogMaker "MSG" "$logStep Lvm2 support added in mkinitcpio!"
	fi
	if [ -e /proc/mdstat ] 
	then
		hooks="$hooks /^HOOKS=/ s/block/block mdadm/"
		LogMaker "MSG" "$logStep Raid (mdadm) support added in mkinitcpio!"
	fi
	if [ -n "$hooks" ]
	then
		sed -i "$hooks" $fileMkinitcpioConf 												\
			&& LogMaker "MSG" "$logStep Hooks detected are defined in $fileMkinitcpioConf" 	\
			|| LogMaker "ERR" "$logStep Impossible to set hooks in $fileMkinitcpioConf"
	fi
}
SetFstab(){ #Use: SetFstab /target
	local target="$1"
	local fstab="$target/etc/fstab"
	genfstab -p -U $target >> $fstab								\
		&& LogMaker "MSG" "$logStep $fstab generated"				\
		|| LogMaker "ERR" "$logStep Impossible to generate $fstab"
}
SetTimezone(){ #Use: SetTimezone /target "America/Sao_Paulo"
	local target="$1"
	local timezone="$2"
	local fileLocaltime="/etc/localtime"
	arch-chroot $target ln -sf /usr/share/zoneinfo/$timezone $fileLocaltime			\
		&& LogMaker "MSG" "$logStep Timezone defined in $fileLocaltime" 			\
		|| LogMaker "ERR" "$logStep Impossible to set timezone in $fileLocaltime"
}
SetHardwareClock(){ #Use: SetHardwareClock /target
	local target="$1"
	arch-chroot $target hwclock --systohc 											 \
		&& LogMaker "MSG" "$logStep Hardware clock defined and /etc/adjtime created" \
		|| LogMaker "ERR" "$logStep Impossible to set hardware clock"
}
SetUsers(){ #Use: SetUsers /target "useraddLine01\nuseraddLine02\n..." 
	local target="$1"
	local users="$2"
	local useraddLine
	while read useraddLine
	do
		eval arch-chroot $target useradd "$useraddLine" '			  \
			&& LogMaker "MSG" "$logStep User '${useraddLine##* }' added!" \
			|| LogMaker "ERR" "$logStep Impossible to add user '${useraddLine##* }'"'
	done <<<"$users"
}
SetPasswords(){ #Use: SetPasswords /target "root:md5pwd\nuser01:md5pwd\n..."
	local target="$1"
	local passwords="$2"
	chpasswd -e -R $target <<<"$passwords" 				\
		&& LogMaker "MSG" "$logStep Passwords defined" 	\
		|| LogMaker "ERR" "$logStep Some or all passwords was impossible to set"
}
