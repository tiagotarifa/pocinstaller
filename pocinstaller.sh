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
readonly PartitionBoot="$(df --output=source "$DirBoot" 2>/dev/null | grep 'dev')"
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
#--------/ Check pocinstaller /------------------------------------------------
#check if commonlib.sh exist
if [ -n "$CommonlibFile" ]
then
	source "$CommonlibFile"
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
#Check if at list one profile exist
if [ -z "$BaseAnswerFile" ]
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
#--------/ Trap session /-------------------------------------------------------
trap "LogMaker 'MSG' 'pocinstaller: Aborted by user!'" 2
#--------/ Main Functions /-----------------------------------------------------
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
	local filePacmanConfOnRoot="/etc/pacman.conf"
	local filePacmanConfOnMounted="$dirTarget/etc/pacman.conf"
	local fileVconsole="$dirTarget/etc/vconsole.conf"
	local fileHostname="$dirTarget/etc/hostname"
	local fileHosts="$dirTarget/etc/hosts"
	local fileFstab="$dirTarget/etc/fstab"
	local fileMkinitcpioConf="$dirTarget/etc/mkinitcpio.conf"
	local fileFirstBootScript="$dirTarget/root/first_boot.sh"
	local fileSystemdUnit="$dirTarget/usr/lib/systemd/system/pocinstaller.service"
	local intelUcode

	LogMaker "LOG" "SystemInstallation 01: Starting stage 'Collecting information from answer file'."
	if grep -Eq 'Intel' /proc/cpuinfo
	then 
		intelUcode="intel-ucode"
		LogMaker "LOG" "SystemInstallation 01: Intel CPU detected! Package intel-ucode will be installed"
	fi

	# It's collect hostname, language, keyboard, timezone, multilib, keymap
	# and grub argumenst (grubArgs) from answer file and set it like a local
	# var. i.e hostname="mycomputer" to local hostname="mycomputer" and 
	# load it.
	eval $(sed -r '/^#/d
		/^( +)?$/d
		/</,$d
		s/^/local /' "$answerFile")

	[ -n "$hostname" ] \
		&& LogMaker "MSG" "SystemInstallation 01: Hostname value loaded!" \
		|| LogMaker "ERR" "SystemInstallation 01: No hostname defined!"
	[ -n "$timezone" ] \
		&& LogMaker "MSG" "SystemInstallation 01: Timezone value loaded!" \
		|| LogMaker "ERR" "SystemInstallation 01: No timezone defined!"
	[ -n "$grubArgs" ] \
		&& LogMaker "MSG" "SystemInstallation 01: Grub arguments loaded!" \
		|| LogMaker "ERR" "SystemInstallation 01: No grub arguments defined!"
	if [ -z "$language" ] 
	then
		local language="en_US.UTF-8"
		LogMaker "WAR" "SystemInstallation 01: No language defined! 'en_US.UTF-8' defined"
	else
		LogMaker "MSG" "SystemInstallation 01: Language value loaded!"
	fi
	if [ -z "$multilib" ] 
	then 
		multilib="yes"
		LogMaker "WAR" "SystemInstallation 01: No multilib defined! Set multilib suport for installation."
	else
		LogMaker "MSG" "SystemInstallation 01: Multilib value loaded!"
	fi
	if [ -z "$keyboard" ] 
	then
		local keyboard="us"
		LogMaker "WAR" "SystemInstallation 01: No keyboard defined. 'us' defined"
	else
		LogMaker "MSG" "SystemInstallation 01: Keyboard value loaded."
	fi
	local passwords="$(sed '
		/<passwords>/,/<\/passwords>/!d
		/^</d
		' "$answerFile")"
 		[ -n "$passwords" ] \
			&& LogMaker "MSG" "SystemInstallation 01: Password(s) value loaded!" \
			|| LogMaker "ERR" "SystemInstallation 01: No root password defined!"
	local users="$(sed '
		/<users>/,/<\/users>/!d
		/^</d
		' "$answerFile")"
		[ -n "$users" ] \
			&& LogMaker "MSG" "SystemInstallation 01: User(s) value loaded!" \
			|| LogMaker "WAR" "SystemInstallation 01: No users to add in target system"
	local locales="$(sed '
		/<locales>/,/<\/locales>/!d
		/^</d
		s/^/\\@/
		s/$/@ s@^#([[:alpha:]])@\\1@;/
		' "$answerFile")"
		if [ -z "$locales" ]
		then
			locales='s/^#en_US/en_US/'
			LogMaker "WAR" "SystemInstallation 01: No locales defined! 'en_US.UTF-8' defined"
		else
			LogMaker "MSG" "SystemInstallation 01: Locale(s) value loaded!"
		fi
	local repositories="$(sed '
		/<repositories>/,/<\/repositories>/!d
		/^</d
		s/^/5aServer = /
		' "$answerFile")"
		if [ -z "$repositories" ]
		then
			repositories='s/^#S/S/'
			LogMaker "WAR" "SystemInstallation 01: No repositories defined! All repositories on mirrorlist file defined."
		else
			LogMaker "MSG" "SystemInstallation 01: Repositores value loaded!"
		fi
	local packages="$(sed '
		/<packages>/,/<\/packages>/!d
		/^</d
		' "$answerFile" | tr '\n' ' ')"
		if [ -z "$packages" ]
		then
			packages=''
			LogMaker "WAR" "SystemInstallation 01: No packages defined! Only 'base' package will be installed."
		else
			LogMaker "MSG" "SystemInstallation 01: Packages value loaded!"
		fi
	local mkinitcpioHooks
	if [ "$(pvs | wc -l)" -gt 1 ] 
	then
		mkinitcpioHooks="/^HOOKS=/ s/block/block lvm2/;"
		LogMaker "MSG" "SystemInstallation 01: Lvm2 support added in mkinitcpio!"
	fi
	if [ -e /proc/mdstat ] 
	then
		mkinitcpioHooks="$mkinitcpioHooks /^HOOKS=/ s/block/block mdadm/"
		LogMaker "MSG" "SystemInstallation 01: Raid (mdadm) support added in mkinitcpio!"
	fi

	#Stage02: Running pre script
	LogMaker "LOG" "SystemInstallation 02: Starting stage 'Running pre script before start (<pre-script>).'"
	local preScript="$(sed '
		/^<pre-script>/,/^<\/pre-script>/!d
		/^</d
		' "$answerFile")"
	if [ -n "$preScript" ]
	then
		LogMaker "MSG" "SystemInstallation 02: Running pre script..."
		(
			eval $preScript
		) 
		if [ $? -eq 0 ]
		then 
			LogMaker "MSG" "SystemInstallation 02: Pre script execution has been done."
		else
			LogMaker "ERR" "SystemInstallation 02: Pre script returned with error. Exiting..."
		fi
	else
		LogMaker "MSG" "SystemInstallation 02: Pre script not defined in answer file."
	fi

	#Stage03: Prepare environment to support the installation
	LogMaker "LOG" "SystemInstallation 03: Starting stage 'Prepare environment to support installation.'"
	sed -i 's/^S/#S/' $fileMirrorlistOnRoot \
		&& LogMaker "MSG" "SystemInstallation 03: Disabled all repositories on '$fileMirrorlistOnRoot'!" \
		|| LogMaker "ERR" "SystemInstallation 03: Impossible to disabled all repositories on '$fileMirrorlistOnRoot'!"
	eval "sed -i '$repositories' $fileMirrorlistOnRoot" \
		&& LogMaker "MSG" "SystemInstallation 03: Repositories pre-defined has been enabled on '$fileMirrorlistOnRoot'!" \
		|| LogMaker "ERR" "SystemInstallation 03: Impossible to set repositories on '$fileMirrorlistOnRoot'!"
	if [ "$multilib" == "yes" ]
	then
		sed -i '/^#\[multilib\]/,/#Include/ s/^#//' $filePacmanConfOnRoot \
			&& LogMaker "MSG" "SystemInstallation 03: Multilib support enabled in '$filePacmanConfOnRoot'" \
			|| LogMaker "ERR" "SystemInstallation 03: Impossible to enable multilib support in '$filePacmanConfOnRoot'" 
	fi

	#Stage04: Install basic packages
	LogMaker "LOG" "SystemInstallation 04: Starting stage 'Install basic packages'"
	pacstrap $dirTarget base grub $intelUcode \
		&& LogMaker "MSG" "SystemInstallation 04: Arch Linux base system was successfully installed!" \
		|| LogMaker "ERR" "SystemInstallation 04: Impossible to install Arch Linux base system!"

	#Stage04: Set up the installed environment
	LogMaker "LOG" "SystemInstallation 05: Starting stage 04: Set up the installed environment"
	genfstab -p -U $dirTarget >> $fileFstab \
		&& LogMaker "MSG" "SystemInstallation 05: /etc/fstab generated" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to generate /etc/fstab "
	eval "sed -ri '$locales' $fileLocaleGen" \
		&& LogMaker "MSG" "SystemInstallation 05: Locales defined in /etc/locales.gen" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set locales in /etc/locales.gen"
	sed -i 's/^S/#S/' $fileMirrorlistOnMounted \
		&& LogMaker "MSG" "SystemInstallation 05: Disable all repositories in /etc/pacman.d/mirrorlist" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to disable all repositories in /etc/pacman.d/mirrorlist"
	eval "sed -i '$repositories' $fileMirrorlistOnMounted" \
		&& LogMaker "MSG" "SystemInstallation 05: Repositories defined in /etc/pacman.d/mirrorlist" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set repositories in /etc/pacman.d/mirrorlist"
	echo "LANG=$language" > $fileLocaleConf \
		&& LogMaker "MSG" "SystemInstallation 05: Language defined in /etc/locale.conf" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set language in /etc/locale.conf"
	echo "KEYMAP=$keyboard" > $fileVconsole \
		&& LogMaker "MSG" "SystemInstallation 05: Keyboard layout defined in /etc/vconsole.conf" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set keyboard layout in /etc/vconsole.conf"
	echo "$hostname" > $fileHostname \
		&& LogMaker "MSG" "SystemInstallation 05: Hostname defined in /etc/hostname" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set hostname in /etc/hostname"
	echo -e "127.0.0.1\t${hostname}.localdomain\t$hostname" >> $fileHosts \
		&& LogMaker "MSG" "SystemInstallation 05: Local DNS defined in /etc/hosts" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set local DNS in /etc/hosts"
	if [ -n "$mkinitcpioHooks" ]
	then
		eval "sed -i '$mkinitcpioHooks' $fileMkinitcpioConf" \
			&& LogMaker "MSG" "SystemInstallation 05: Hooks detected are defined in /etc/mkinitcpio.conf" \
			|| LogMaker "ERR" "SystemInstallation 05: Impossible to set hooks in /etc/mkinitcpio.conf"
	fi
	if [ "$multilib" == "yes" ]
	then
		sed -i '/^#\[multilib\]/,/#Include/ s/^#//' $filePacmanConfOnMounted\
			&& LogMaker "MSG" "SystemInstallation 05: Multilib support enabled in '$filePacmanConfOnMounted'" \
			|| LogMaker "ERR" "SystemInstallation 05: Impossible to enable multilib support in '$filePacmanConfOnMounted'" 
	fi
	arch-chroot $dirTarget ln -sf /usr/share/zoneinfo/$timezone /etc/localtime \
		&& LogMaker "MSG" "SystemInstallation 05: Timezone defined in /etc/localtime" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set timezone in /etc/localtime"
	arch-chroot $dirTarget hwclock --systohc \
		&& LogMaker "MSG" "SystemInstallation 05: Hardware clock defined and /etc/adjtime created" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to set hardware clock"
	arch-chroot $dirTarget locale-gen \
		&& LogMaker "MSG" "SystemInstallation 05: Locales generated" \
		|| LogMaker "ERR" "SystemInstallation 05: Impossible to generate locales"

	#Stage06: Change root password and add new users.
	LogMaker "LOG" "SystemInstallation 06: Starting stage 'Change root password and add new users'"
	while read useraddLine
	do
		eval arch-chroot $dirTarget useradd "$useraddLine"' || echo "erro ${useraddLine##* }" ' \
			&& LogMaker "MSG" "SystemInstallation 06: User '${useraddLine##* }' added" \
			|| LogMaker "ERR" "SystemInstallation 06: Impossible to add user '${useraddLine##* }'"
	done <<<"$users"
	chpasswd -e -R $dirTarget <<<"$passwords" \
		&& LogMaker "MSG" "SystemInstallation 06: Passwords defined" \
		|| LogMaker "ERR" "SystemInstallation 06: Some or all passwords was impossible to set"

	#Stage07: Set up the boot process
	LogMaker "LOG" "SystemInstallation 07: Starting stage 'Set up the boot process'"
	arch-chroot $dirTarget mkinitcpio -p linux \
		&& LogMaker "MSG" "SystemInstallation 07: RAM filesystem generated (mkinitcpio)" \
		|| LogMaker "ERR" "SystemInstallation 07: Impossible to generate RAM filesystem (mkinitcpio)"
	LogMaker "MSG" "SystemInstallation 07: Installing grub..."
	eval arch-chroot $dirTarget grub-install $grubArgs $diskBoot\
		&& LogMaker "MSG" "SystemInstallation 07: Grub installed with arguments '$grubArgs'" \
		|| LogMaker "ERR" "SystemInstallation 07: Impossible to install grub! Grub arguments was '$grubArgs'"
	if IsEfi 
	then 
		#Workaround for some motherboards
		#Reference: https://wiki.gentoo.org/wiki/Handbook:AMD64/Installation/Bootloader
		(
		mkdir -p $dirBoot/efi/efi/boot
		cp $dirBoot/efi/efi/arch/grubx64.efi $dirBoot/efi/efi/boot/bootx64.efi
		) \
			&& LogMaker "MSG" "SystemInstallation 07: Workaround made for EFI bios" \
			|| LogMaker "WAR" "SystemInstallation 07: Impossible to make a workaround for EFI bios"
	fi

	#Stage08: Set up the first boot
	LogMaker "LOG" "SystemInstallation 08: Starting stage 'Set up for the first boot'"
	LogMaker "MSG" "SystemInstallation 08: Downloading all packages to install on first boot"
	arch-chroot $dirTarget pacman -Syw --noconfirm $packages \
		&& LogMaker "MSG" "SystemInstallation 08: Downloaded additional packages." \
		|| LogMaker "WAR" "SystemInstallation 08: Impossible to download additional packages."
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
		&& LogMaker "MSG" "SystemInstallation 08: '$fileFirstBootScript' will run on first boot." \
		|| LogMaker "ERR" "SystemInstallation 08: Impossible to enable '$fileFirstBootScript' to run on first boot."
	(echo '#!/bin/bash'
	 sed '/^LogMaker/,/^}/!d
		s@logFile=.*@logFile="/var/log/pocinstaller.sh"@
		' $CommonLibFile
	 echo "
	 LogMaker 'MSG' 'SystemInstallation 12: Starting FirstBoot step'
	 pacman -S $packages \\
		&& LogMaker "MSG" "SystemInstallation 12: Additional packages installed." \
		|| LogMaker "WAR" "SystemInstallation 12: Impossible to install aditional packages."
	 systemctl disable pocinstaller
	 LogMaker "MSG" "SystemInstallation 12: Installation has been finished."
	 rm $fileFirstBootScript
	 shutdown -r now
	 "
	) > $fileFirstBootScript
	chmod +x $fileFirstBootScript
	#Stage09: Running chroot pos script
	LogMaker "LOG" "SystemInstallation 09: Starting stage 'Running chrooted script (<chroot-script>).'"
	local chrootScript="$(sed '
		/^<chroot-script>/,/^<\/chroot-script>/!d
		/^</d
		' "$answerFile")"
	if [ -n "$chrootScript" ]
	then
		LogMaker "MSG" "SystemInstallation 09: Running chrooted script..."
		(
			eval $chrootScript
		) 
		if [ $? -eq 0 ]
		then 
			LogMaker "MSG" "SystemInstallation 09: Chrooted script execution has been done."
		else
			LogMaker "ERR" "SystemInstallation 09: Chrooted script returned with error(s). Exiting..."
		fi
	else
		LogMaker "MSG" "SystemInstallation 09: Chrooted script not defined in answer file."
	fi
	#Stage10: Running pos script
	LogMaker "LOG" "SystemInstallation 10: Starting stage 'Running pos script (<pos-script>).'"
	local posScript="$(sed '
		/^<pos-script>/,/^<\/pos-script>/!d
		/^</d
		' "$answerFile")"
	if [ -n "$posScript" ]
	then
		LogMaker "MSG" "SystemInstallation 10: Running pos script..."
		(
			eval $posScript
		) 
		if [ $? -eq 0 ]
		then 
			LogMaker "MSG" "SystemInstallation 10: Pos script execution has been done."
		else
			LogMaker "ERR" "SystemInstallation 10: Pos script returned with error(s). Exiting..."
		fi
	else
		LogMaker "MSG" "SystemInstallation 10: Pos script not defined in answer file."
	fi

	#Stage11: rebooting
	LogMaker "LOG" "SystemInstallation 11: Finalizing the LOG and restarting"
	umount -R $dirTarget
	cp "$LogFile" "$dirTarget/var/log/"
	shutdown -r now
}
CollectingDataFromMenu(){
	local step=Keymap
	local profileFile
	local -x hostname timezone locale keymap consoleFont consoleFontMap multilib
	local -x repositories rootPassword usersList usersPassword language whereAmI
	local -x profile
	local -x grubArgs="$(GetGrubArguments)"
	LogMaker "LOG" "GUI Menu: Stating GUI menu"
	while :
	do
		whereAmI="\Zr|Keymap|Hostname|TZone|Locale|Lang|Repo|RootPwd|Users|Multilib|Profile|\ZR"
		case $step in
		      Keymap) whereAmI="${whereAmI/Keymap/\\Z1Keymap\\Z0}"
					  if keymap="$(GetKeymap)"
				  	  then
					  	  step=Hostname
					  else
						  LogMaker "MSG" "Exited by user!"
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
			 Summary) whereAmI='|\ZrStartAgain<-\Z1Summary\Z0->CreateAnswerFile->Installation\ZR'
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
	whereAmI='|\ZrStartAgain<-Summary->\Z1CreateAnswerFile\Z0->Installation\ZR'
	profileFile=$(MakeAnswerFile "$profile")
	whereAmI='|\ZrStartAgain<-Summary->CreateAnswerFile->\Z1Installation\Z0\ZR'
	if GuiYesNo "Installation" "Do you want to start the installation process?" 
	then
		LogMaker "LOG" "GUI Menu: Calling installation process!"
		SystemInstallation $profileFile || return
	else
		LogMaker "LOG" "GUI Menu: Exited!"
	fi
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
			-a|--answer-file) LogMaker "LOG" "Piece Of Cake Installer has been started in automatic mode"
							  ValidatingEnvironment --text-mode || exit 1
							  #SetNetworkConfiguration --text-mode
							  SetDateAndTime --text-mode
							  SystemInstallation $2
							  exit
						 	  ;;
						  -g) LogMaker "LOG" "Piece Of Cake Installer has been started in GUI mode"
							  ValidatingEnvironment || exit 1
							  #SetNetworkConfiguration
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
