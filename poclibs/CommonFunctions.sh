#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# Commonlib.sh: Functions to support all others functions and pocinstaller.sh
# Site        : https://github.com/tiagotarifa/pocinstaller
# Author      : Tiago Tarifa Munhoz
# License     : GPL
#
#--------/ Description /--------------------------------------------------------
#     This script has functions to handle with loging, user interface (GUI), and
# other stufs. Don't try to run this file, nothing will happend.
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
#    Under development
#
#-------------------------------------------------------------------------------
LogMaker() { #Use: <MSG|LOG|WAR|ERR> <Message>
	local logFile="$LogFile"
	local level="${1^^}" ; shift
	local message="$@"
	local date="[$(date '+%Y/%m/%d %H:%M:%S')]"

	case "$level" in
		  LOG) echo -e "${date}INF: $message" >> "$logFile"
			   ;;
		  MSG) echo -e "---Message: $message"
			   echo "${date}INF: $message" >> "$logFile"
			   ;;
		  WAR) echo -e "---Warning: $message.\n    More details in '$logFile'"
			   echo "${date}${level}: ${message//\\[nt]/}" >> "$logFile"
			;;
		  ERR) echo -e "---$level: $message.\n    More details in '$logFile'\n\nLeaving out..."
			   cat <<-_eof_ >> "$logFile"
				${date}${level}: ${message//\\[nt]/}
				  Occurred when calling function '${FUNCNAME[1]}' line '${BASH_LINENO[1]}'
				  Backtrace:'${FUNCNAME[*]}'
				_eof_
				local output depth=0
				while output="$(caller $depth)"
				do
					printf '%s\n' "Caller $depth: $output" >>$logFile
					depth="$(( depth + 1 ))"
				done
				exit 255
			;;
	esac
}
WaitingNineSeconds(){
	local textMode="$1"
	local text="Press \033[31mCTRL+C\033[0m to cancel this installation"
	local lines=$(tput lines)
	local seconds
	echo -e "$text"
	for ((seconds=8;seconds>=0;seconds--))
	do
		if [ $seconds -gt 5 ] 
		then 
			printf "\033[32m$seconds...\033[0m"
			sleep 1
			continue
		fi

		[ $seconds -ge 3 ] && ( printf "\033[33m$seconds...\033[0m" ; sleep 1 )
		[ $seconds -lt 3 ] && ( printf "\033[31m$seconds...\033[0m" ; sleep 1 )
	done
}
ValidatingEnvironment(){
	local title="Environment Validation"
	local text="Checking if everything is ok:\n"
	local memorySize="$MachineMemSize"
	local dirTarget="$DirTarget"
	local dirBoot="$DirBoot"
	local mountedRootDir="$MountedRootDir"
	local mountedBootDir="$MountedBootDir"
	local swap="$SwapActive"
	local textMode="$1"
	local efiFirmware="$EfiFirmware"
	local alertNeeded rtn

	local errorText
	#Memory
	if [ "$memorySize" -lt 524288 ]
	then
		text="$text* Memory \Z1low\Z0: $memorySize\n"
		alertNeeded=1
	else
		text="$text* Memory ok: $memorySize\n"
	fi
	#Is partition mounted for root installation?
	if [ "$mountedRootDir" == "$dirTarget" ]
	then
		text="$text* Root partition is mounted in '$dirTarget'.\n"
		#Root partition size
		if [ "${PartitionRootSize%M}" -lt 800 ]
		then
			errorText="$errorText* Partition root with insufficient size: 
				${PartitionRootSize##* }.\Z1Minimal is 800MB\Z0\n"
		else
			text="$text* Partition root size ok: ${PartitionRootSize##* }\n"
		fi
	else
		errorText="$errorText* Have you mounted your root partition in '$dirTarget' ?\n"
	fi
	#Is partition mounted for /boot?
	if [ "$mountedBootDir" == "$dirBoot" ]
	then
		text="$text* Boot partition is mounted in '$dirBoot'.\n"
		#Boot partition size
		if [ "${PartitionBootSize%M}" -lt 100 ]
		then
			errorText="$errorText* Partition boot with insufficient size:
			${PartitionBootSize##* }.\Z1Minimal is 100MB\Z0\n"
		else
			text="$text* Partition boot size ok: ${PartitionBootSize##* }\n"
		fi
	else
		errorText="$errorText* Have you mounted your boot partition in '$dirBoot' ?\n"
	fi
	#Is there a active swap?
	if [ -n "$swap" ]
	then
		text="$text* Swap is on in $swap\n"
	else
		text="$text* \Z1Have you activated your swap partition?\Z0\n"
		alertNeeded=1
	fi
	#Bios or EFI?
	if IsEfi
	then
		text="$text* It has a EFI support\n"
	else
		text="$text* It has a bios support only\n"
	fi
	if [ -n "$errorText" ]
	then
		if [ -n "$textMode" ]
		then
			LogMaker "ERR" "SystemCheck: Some requirements have not been met:\n$errorText"
		else
			GuiMessageBox "$title" "$text\nSome requirements have not been met:\n${errorText}
				\Z1Impossible to continue\Z0!"
			LogMaker "ERR" "SystemCheck: Some requirements have not been met:\n$errorText" > /dev/null
		fi
	else
		if [ -n "$textMode" ]
		then
			text="$(sed -r '
				s/\\Z1/\\033[31m/
				s/\\Z0/\\033[0m/
				' <<<"$text")"
			LogMaker "MSG" "SystemCheck: $text"
			WaitingNineSeconds
		else
			LogMaker "LOG" "SystemCheck: $text"
			GuiMessageBox "$title" "$text"
			return 
		fi
	fi
}
MakeAnswerFile(){
	local title="AnswerFile"
	local profileFile="$1"
	local answerFile="/tmp/modified_${profileFile##*/}"
	local text="Answer file '$answerFile' generated! You can use this file to
		make automatic mass installs or a new one." 
	eval 'cat <<-_eof_ >"$answerFile"
	'"$(cat $profileFile)"'	
	_eof_'
	GuiMessageBox "$title" "$text" || return
	LogMaker "LOG" "AnswerFile: Answer file generated in '$answerFile'"
	echo "$answerFile"
}
IsEfi(){ #Returns 0 if it is a EFI system and 1 if its not.
	[ -d "$efiFirmware" ]
}
CreateFirstBootScript(){
	file="$1"
	(echo '#!/bin/bash'
	 sed '/^LogMaker/,/^}/!d
		s@logFile=.*@logFile="/var/log/pocinstaller.sh"@
		' $FileCommonFunctions
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
	) > $file
	if [ "$?" -eq = 0 ]
	then
		chmod +x $file
		LogMaker "MSG" "$logStep First boot script created"
	else
		LogMaker "ERR" "$logStep Impossible to create the first boot script."
	fi
}
RunArgumentAsScript(){
	local script="$@"
	if [ -n "$script" ]
	then
		LogMaker "MSG" "$logStep Running custom script from answer file"
		(
			eval "$script"
		) && LogMaker "MSG" "$logStep Script execution has been done." \
		  || LogMaker "ERR" "$logStep Script returned with error. Exiting..."
	else
		LogMaker "MSG" "$logStep Script not defined in answer file."
	fi
}
