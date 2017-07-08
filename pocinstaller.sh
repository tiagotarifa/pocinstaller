#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# pocinstaller.sh: Manual or automatic installer for Archlinux (under development)
#
# Site		: https://github.com/tiagotarifa/pocinstaller
# Author	: Tiago Tarifa Munhoz
# License	: GPLv3
#
#--------/ Description /--------------------------------------------------------
#     Piece of Cake installer aims to be a easy and fast installer for Arch 
# Linux. It's allow you to install by filling questions or using a anwser file
# like an argument.
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
#--------/ History /------------------------------------------------------------
#	Version: None release in:Under development 
#--------/ Loggin /-------------------------------------------------------------
readonly LogFile='/var/log/pocinstaller.log'
exec 2>> $LogFile
#--------/ Constants /----------------------------------------------------------
#Texts
readonly BackTitle="Piece of Cake Installer"
readonly HelpMessage="    Arch Linux installer guided graphically or automatically using a 
    response file.
    USE:
        ${0##*/} [-h|-V|-T] [-a answerFile.cfg]
    OPTIONS:
       -a, --answer-file  answerFile.cfg
                      Do a automatic install oriented by a answer file. 
       -h, --help     Show this help and exit
       -V, --version  Show version and exit
    NOTES:
       -The graphical environment will start if no arguments are passed.
       -Enter the graphical mode to make an answer file. It will be
        saved in the /tmp/modified_nameOfProfile.cfg.
"
#Directories
readonly DirProfiles="profiles/"
readonly DirTarget="/mnt"
readonly DirBoot="$DirTarget/boot"
#Partition
readonly PartitionBoot="$(df --output=source "$DirBoot" 2>/dev/null | grep "$DirBoot")"
#Disk
readonly DiskBoot=${PartitionBoot%[0-9]}
#Collecting environment information
readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
readonly MountedRootDir="$(df --output=target "$DirTarget" 2>/dev/null | grep "$DirTarget")"
readonly PartitionRootSize="$(df --output=size -BM /mnt | tail -1)"
readonly MountedBootDir="$(df --output=target "$DirBoot" 2>/dev/null | grep "$DirBoot")"
readonly PartitionBootSize="$(df --output=size -BM /mnt/boot | tail -1)"
readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
readonly EfiFirmware='/sys/firmware/efi/efivars'
[ -s '/var/lib/pocinstaller/commonlib.sh' ] \
	&& readonly CommonlibFile='/var/lib/pocinstaller/commonlib.sh'
[ -s 'commonlib.sh' ] \
	&& readonly CommonlibFile='commonlib.sh'
[ -s '/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg' ] \
	&& readonly BaseAnswerFile='/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg'
[ -s 'profiles/Only_Base_Packages.cfg' ] \
	&& readonly BaseAnswerFile='profiles/Only_Base_Packages.cfg'
#--------/ Main Functions /-----------------------------------------------------
ValidatingPocInstaller(){
	local commonlib="$CommonlibFile"
	local baseAnswerFile="$BaseAnswerFile"
	if [ -n "$commonlib" ]
	then
		source "$commonlib"
	else
		cat <<-_eof_ 
		Error!
		   Library file 'commonlib.sh' is not found!
		   It should be in '$PWD/commonlib.sh'
		   or in '/var/lib/pocinstaller/commonlib.sh'!
		   POC Installer can't goes on!
		   Exiting...
		_eof_
		exit 1
	fi
	if [ -z "$baseAnswerFile" ]
	then
		cat <<-_eof_ 
		Error!
		   Profile file is no found!
		   It should be in '$PWD/profiles/Only_Base_Packages.cfg'
		   or in '/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg'!
		   POC Installer can't goes on!
		   Exiting...
		_eof_
		exit 1
	fi
}
SystemInstallation(){
	local answerFile="$1"
	if [ ! -s "$answerFile" ]
	then
		LogMaker "ERR" "Answer file do not exist or it is empty."
	fi
	local dirTarget="$DirTarget"
	local dirBoot="$DirBoot"
	local diskBoot="$DiskBoot"
	local fileLocaleGen="$dirTarget/etc/locale.gen"
	local fileLocaleConf="$dirTarget/etc/locale.conf"
	local fileMirrorlistOnRoot="/etc/pacman.d/mirrorlist"
	local fileMirrorlistOnMounted="$dirTarget/etc/pacman.d/mirrorlist"
	local fileVconsole="$dirTarget/etc/vconsole.conf"
	local fileHostname="$dirTarget/etc/hostname"
	local fileHosts="$dirTarget/etc/hosts"
	local fileFstab="$dirTarget/etc/fstab"
	local fileMkinitcpioConf="$dirTarget/etc/mkinitcpio.conf"
	local intelUcode
	if grep -Eq 'Intel' /proc/cpuinfo
	then 
		intelUcode="intel-ucode"
		LogMaker "LOG" "SystemInstallation: Intel CPU detected! Package intel-ucode will be installed"
	fi

	LogMaker "LOG" "SystemInstallation: Starting stage 1: Collecting information from answer file."
	# It's collect hostname, language, keyboard, timezone, multilib, keymap
	# and grub argumenst (grubArgs) from answer file and set it like a local
	# var. i.e hostname="mycomputer" to local hostname="mycomputer" and 
	# load it.
	eval $(sed -r '/^#/d
		/^( +)?$/d
		/</,$d
		s/^/local /' "$answerFile")

	[ -n "$hostname" ] \
		&& LogMaker "MSG" "SystemInstallation 1: Hostname value loaded!" \
		|| LogMaker "ERR" "SystemInstallation 1: No hostname defined!"
	[ -n "$timezone" ] \
		&& LogMaker "MSG" "SystemInstallation 1: Timezone value loaded!" \
		|| LogMaker "ERR" "SystemInstallation 1: No timezone defined!"
	[ -n "$grubArgs" ] \
		&& LogMaker "MSG" "SystemInstallation 1: Grub arguments loaded!" \
		|| LogMaker "ERR" "SystemInstallation 1: No grub arguments defined!"
	if [ -z "$language" ] 
	then
		local language="en_US.UTF-8"
		LogMaker "WAR" "SystemInstallation 1: No language defined! 'en_US.UTF-8' defined"
	else
		LogMaker "MSG" "SystemInstallation 1: Language value loaded!"
	fi
	if [ -z "$multilib" ] 
	then 
		multilib="yes"
		LogMaker "WAR" "SystemInstallation 1: No multilib defined! Set multilib suport for installation."
	else
		LogMaker "MSG" "SystemInstallation 1: Multilib value loaded! Set multilib suport for installation."
	fi
	if [ -z "$keyboard" ] 
	then
		local keyboard="us"
		LogMaker "WAR" "SystemInstallation 1: No keyboard defined. 'us' defined"
	else
		LogMaker "MSG" "SystemInstallation 1: Keyboard value loaded."
	fi
	local passwords="$(sed '
		/<passwords>/,/<\/passwords>/!d
		/^</d
		' "$answerFile")"
 		[ -n "$passwords" ] \
			&& LogMaker "MSG" "SystemInstallation 1: Password value loaded!" \
			|| LogMaker "ERR" "SystemInstallation 1: No root password defined!"
	local users="$(sed '
		/<users>/,/<\/users>/!d
		/^</d
		' "$answerFile")"
		[ -n "$users" ] \
			&& LogMaker "MSG" "SystemInstallation 1: Users value loaded!" \
			|| LogMaker "WAR" "SystemInstallation 1: No users to add in target system"
	local locales="$(sed '
		/<locales>/,/<\/locales>/!d
		/^</d
		s/^/\\@/
		s/$/@ s@^#([[:alpha:]])@\\1@;/
		' "$answerFile")"
		if [ -z "$locales" ]
		then
			locales='s/^#en_US/en_US/'
			LogMaker "WAR" "SystemInstallation 1: No locales defined! 'en_US.UTF-8' defined"
		else
			LogMaker "MSG" "SystemInstallation 1: Users value loaded!"
		fi
	local repositories="$(sed '
		/<repositories>/,/<\/repositories>/!d
		/^</d
		s/^/\\@/
		s/$/@ s@^#@@;/
		' "$answerFile" | tr '\n' ' ')"
		if [ -z "$repositories" ]
		then
			repositories='s/^#S/S/'
			LogMaker "WAR" "SystemInstallation 1: No repositories defined! All repositories on mirrorlist file defined."
		else
			LogMaker "MSG" "SystemInstallation 1: Repositores value loaded!"
		fi
	local packages="$(sed '
		/<packages>/,/<\/packages>/!d
		/^</d
		' "$answerFile" | tr '\n' ' ')"
		if [ -z "$packages" ]
		then
			packages=''
			LogMaker "WAR" "SystemInstallation 1: No packages defined! Only 'base' package will be installed."
		else
			LogMaker "MSG" "SystemInstallation 1: Packages value loaded!"
		fi
	local mkinitcpioHooks
	if [ "$(pvs | wc -l)" -gt 1 ] 
	then
		mkinitcpioHooks="/^HOOKS=/ s/block/block lvm2/;"
		LogMaker "MSG" "SystemInstallation 1: Lvm2 support added in mkinitcpio!"
	fi
	if [ -e /proc/mdstat ] 
	then
		mkinitcpioHooks="$mkinitcpioHooks /^HOOKS=/ s/block/block mdadm/"
		LogMaker "MSG" "SystemInstallation 1: Raid (mdadm) support added in mkinitcpio!"
	fi

	#Stage2: Prepare environment to support the installation
	LogMaker "LOG" "SystemInstallation: Starting stage 2: Prepare environment to support installation."
	sed -i 's/^S/#S/' $fileMirrorlistOnRoot \
		&& LogMaker "MSG" "SystemInstallation 2: Disabled all repositories on '$fileMirrorlistOnRoot'!" \
		|| LogMaker "ERR" "SystemInstallation 2: Impossible to disabled all repositories on '$fileMirrorlistOnRoot'!"
	eval "sed -i '$repositories' $fileMirrorlistOnRoot" \
		&& LogMaker "MSG" "SystemInstallation 2: Repositories from answer file are defined on '$fileMirrorlistOnRoot'!" \
		|| LogMaker "ERR" "SystemInstallation 2: Impossible to set repositories on '$fileMirrorlistOnRoot'!"

	#Stage3: Install basic packages
	LogMaker "LOG" "SystemInstallation: Starting stage 3: Install basic packages"
	pacstrap $dirTarget base grub $intelUcode \
		&& LogMaker "MSG" "SystemInstallation 3: Arch Linux base system was successfully installed!" \
		|| LogMaker "ERR" "SystemInstallation 3: Impossible to install Arch Linux base system!"

	#Stage4: Set up the installed environment
	LogMaker "LOG" "SystemInstallation: Starting stage 4: Set up the installed environment"
	genfstab -p -U $dirTarget >> $fileFstab \
		&& LogMaker "MSG" "SystemInstallation 4: /etc/fstab generated" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to generate /etc/fstab "
	eval "sed -ri '$locales' $fileLocaleGen" \
		&& LogMaker "MSG" "SystemInstallation 4: Locales defined in /etc/locales.gen" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set locales in /etc/locales.gen"
	sed -i 's/^S/#S/' $fileMirrorlistOnMounted \
		&& LogMaker "MSG" "SystemInstallation 4: Disable all repositories in /etc/pacman.d/mirrorlist" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to disable all repositories in /etc/pacman.d/mirrorlist"
	eval "sed -i '$repositories' $fileMirrorlistOnMounted" \
		&& LogMaker "MSG" "SystemInstallation 4: Repositories defined in /etc/pacman.d/mirrorlist" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set repositories in /etc/pacman.d/mirrorlist"
	echo "LANG=$language" > $fileLocaleConf \
		&& LogMaker "MSG" "SystemInstallation 4: Language defined in /etc/locale.conf" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set language in /etc/locale.conf"
	echo "KEYMAP=$keyboard" > $fileVconsole \
		&& LogMaker "MSG" "SystemInstallation 4: Keyboard layout defined in /etc/vconsole.conf" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set keyboard layout in /etc/vconsole.conf"
	echo "$hostname" > $fileHostname \
		&& LogMaker "MSG" "SystemInstallation 4: Hostname defined in /etc/hostname" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set hostname in /etc/hostname"
	echo -e "127.0.0.1\t${hostname}.localdomain\t$hostname" >> $fileHosts \
		&& LogMaker "MSG" "SystemInstallation 4: Local DNS defined in /etc/hosts" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set local DNS in /etc/hosts"
	if [ -n "$mkinitcpioHooks" ]
	then
		eval "sed -i '$mkinitcpioHooks' $fileMkinitcpioConf" \
			&& LogMaker "MSG" "SystemInstallation 4: Hooks detected are defined in /etc/mkinitcpio.conf" \
			|| LogMaker "ERR" "SystemInstallation 4: Impossible to set hooks in /etc/mkinitcpio.conf"
	fi
	arch-chroot $dirTarget ln -sf /usr/share/zoneinfo/$timezone /etc/localtime \
		&& LogMaker "MSG" "SystemInstallation 4: Timezone defined in /etc/localtime" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set timezone in /etc/localtime"
	arch-chroot $dirTarget hwclock --systohc \
		&& LogMaker "MSG" "SystemInstallation 4: Hardware clock defined and /etc/adjtime created" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to set hardware clock"
	arch-chroot $dirTarget locale-gen \
		&& LogMaker "MSG" "SystemInstallation 4: Locales generated" \
		|| LogMaker "ERR" "SystemInstallation 4: Impossible to generate locales"

	#Stage5: Change root password and add new users.
	LogMaker "LOG" "SystemInstallation: Starting stage 5: Change root password and add new users"
	while read useraddLine
	do
		eval arch-chroot $dirTarget useradd "$useraddLine"' || echo "erro ${useraddLine##* }" ' \
			&& LogMaker "MSG" "SystemInstallation 5: User '${useraddLine##* }' added" \
			|| LogMaker "ERR" "SystemInstallation 5: Impossible to add user '${useraddLine##* }'"
	done <<<"$users"
	chpasswd -e -R $dirTarget <<<"$passwords" \
		&& LogMaker "MSG" "SystemInstallation 5: Passwords defined" \
		|| LogMaker "ERR" "SystemInstallation 5: Some or all passwords was impossible to set"

	#Stage6: Set up the boot process
	LogMaker "LOG" "SystemInstallation: Starting stage 5: Set up the boot process"
	arch-chroot $dirTarget mkinitcpio -p linux $diskBoot \
		&& LogMaker "MSG" "SystemInstallation 6: RAM filesystem generated (mkinitcpio)" \
		|| LogMaker "ERR" "SystemInstallation 6: Impossible to generate RAM filesystem (mkinitcpio)"
	eval arch-chroot $dirTarget grub-install $grubArgs \
		&& LogMaker "MSG" "SystemInstallation 6: Grub installed with arguments '$grubArgs'" \
		|| LogMaker "ERR" "SystemInstallation 6: Impossible to install grub! Grub arguments was '$grubArgs'"
	if IsEfi 
	then 
		#Workaround for some motherboards
		#Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader
		(
		mkdir -p $dirBoot/efi/efi/boot
		cp $dirBoot/efi/efi/arch/grubx64.efi $dirBoot/efi/efi/boot/bootx64.efi
		) \
			&& LogMaker "MSG" "SystemInstallation 6: Workaround made for EFI bios" \
			|| LogMaker "WAR" "SystemInstallation 6: Impossible to make a workaround for EFI bios"
	fi

	#Stage7: Set up the first boot
	LogMaker "LOG" "SystemInstallation: Starting stage 7: Set up the first boot"
	arch-chroot $dirTarget pacman -Syw $packages \
		&& LogMaker "MSG" "SystemInstallation 7: Downloaded additional packages." \
		|| LogMaker "WAR" "SystemInstallation 7: Impossible to download additional packages."
}
CollectingDataFromMenu(){
	local step=Keymap
	local -x hostname timezone locale keymap consoleFont consoleFontMap multilib
	local -x repositories rootPassword usersList usersPassword language whereAmI
	local -x profile
	local -x grubArgs="$(GetGrubArguments)"
	LogMaker "LOG" "SystemInstallation: Stating GUI menu"
	while :
	do
		whereAmI="\Zr|Keymap|Hostname|TZone|Locale|Lang|Repo|RootPwd|Users|Multilib|Profile|\ZR"
		case $step in
		      Keymap) whereAmI="${whereAmI/Keymap/\\Z1Keymap\\Z0}"
					  if keymap="$(GetKeymap)"
				  	  then
					  	  step=Hostname
					  else
						  return 1
					  fi
					  ;;
			Hostname) whereAmI="${whereAmI/Hostname/\\Z1Hostname\\Z0}"
					  if hostname="$(GetHostname)"
					  then
					      step=Timezone
					  else
						  step=Keymap
					  fi
					  ;;
		    Timezone) whereAmI="${whereAmI/TZone/\\Z1TZone\\Z0}"
					  if timezone="$(GetTimezone)"
					  then 
						  step=Locale
					  else
						  step=Hostname
					  fi
					  ;;
			  Locale) whereAmI="${whereAmI/Locale/\\Z1Locale\\Z0}"
					  if locale="$(GetLocale)"
				  	  then
					      step=Language
					  else
						  step=Timezone
					  fi
					  ;;
			Language) whereAmI="${whereAmI/Lang/\\Z1Lang\\Z0}"
					  if language="$(GetLanguage "$locale")"
				  	  then
					      step=Repositories
					  else
						  step=Locale
					  fi
					  ;;
		Repositories) whereAmI="${whereAmI/Repo/\\Z1Repo\\Z0}"
					  if repositories="$(GetRepositories)" 
					  then 
					  	  step=RootPassword
					  else
						  step=Language
					  fi
					  ;;
		RootPassword) whereAmI="${whereAmI/RootPwd/\\Z1RootPwd\\Z0}"
					  if rootPassword="$(GetRootPassword)" 
					  then 
						  step=Users
					  else
						  step=Repositories
					  fi
					  ;;
			   Users) whereAmI="${whereAmI/Users/\\Z1Users\\Z0}"
					  if usersList="$(GetUsers)"
			   		  then
						  usersPassword="$(grep -Eo '[[:alnum:]]{1,}:.+$'<<<"$usersList")"
						  usersList="$(sed 's/:.*//' <<<"$usersList")"
						  step=Multilib
					  else
						  step=RootPassword
					  fi
					  ;;
			Multilib) whereAmI="${whereAmI/Multilib/\\Z1Multilib\\Z0}"
					  if multilib="$(GetMultilib)" 
					  then 
						  step=Profile
					  else
						  step=Users
					  fi
					  ;;
			 Profile) whereAmI="${whereAmI/Profile/\\Z1Profile\\Z0}"
					  if profile="$(GetProfiles)" 
					  then 
						  step=Summary
					  else
						  step=Multilib
					  fi
					  ;;
			 Summary) whereAmI='|\ZrStartAgain<-\Z1Summary\Z0->CreateAnswerFile\ZR'
					  if GetSummary
				 	  then
						  #Fixing $locale changing '#' to ' '
						  locale="$( 
						  	sed '
								:a;N;$!ba
								s/#/ /g
								'<<<"$locale")"
						  break
					  else
						  hostname='' timezone='' locale='' language=''
						  keymap='' repositories='' rootPassword='' usersList=''
						  multilib='' usersPassword='' profile=''
						  step=Keymap
					  fi
					  ;;
		esac
	done
	[ -n "$hostname" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Hostname OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No hostname defined!"
	[ -n "$timezone" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Timezone OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No Timezone defined!"
	[ -n "$locale" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Locale OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No locale defined!"
	[ -n "$language" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Language OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No language defined!"
	[ -n "$keymap" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Keymap OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No keymap defined!"
	[ -n "$repositories" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Repositories OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No repositories defined!"
	[ -n "$rootPassword" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Root Password OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No root password defined!"
	[ -n "$usersList" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Users list OK!" \
		|| LogMaker "LOG" "GUI Menu debug: No users list defined!"
	[ -n "$multilib" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Multilib OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No multilib defined!"
	[ -n "$usersPassword" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Users passwords OK!" \
		|| LogMaker "LOG" "GUI Menu debug: No users passwords defined!"
	[ -n "$profile" ] \
		&& LogMaker "LOG" "GUI Menu Debug: Profile OK!" \
		|| LogMaker "ERR" "GUI Menu debug: No profile defined!"
	whereAmI='|\ZrStartAgain<-Summary->\Z1CreateAnswerFile\Z0'
	MakeAnswerFile "$profile"
}
main() {
	local args noTime
	args=$(getopt -u -o h,V,a: --long help,version,answer-file: -n "$0" -- "$@") \
		|| exit 1
	#Looking for -h or --help option
	grep -Eqs -- '-h|--help' <<<"$args"	\
		&& args='-h'
	#Looking for -V or --version
	grep -Eqs -- '-V|--version' <<<"$args"	\
		&& args='-V'
	#If no arguments start graphical interface
	[ -z "$1" ] && args='-g'
	eval set -- "$args"
	while :
	do
		case $1 in
					 	  -h) echo "$HelpMessage"
						 	  exit
						 	  ;;
				 	 	  -V) grep -m1 -Eo 'Version:.+' "$0"
						 	  exit
						 	  ;;
			-a|--answer-file) ValidatingPocInstaller
							  LogMaker "LOG" "Piece Of Cake Installer has been started in automatic mode"
							  ValidatingEnvironment --text-mode || exit 1
							  SetNetworkConfiguration --text-mode
							  SetDateAndTime --text-mode
							  SystemInstallation $2
							  exit
						 	  ;;
						  -g) ValidatingPocInstaller
							  LogMaker "LOG" "Piece Of Cake Installer has been started in GUI mode"
							  ValidatingEnvironment || exit 1
							  SetNetworkConfiguration
							  SetDateAndTime
							  CollectingDataFromMenu 
							  exit
						  	  ;;
						   *) echo -e "Error! Illegal argument.\n$HelpMessage"
							  exit 1
							  ;;
		esac
	done
}
main $@
