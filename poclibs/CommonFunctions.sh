#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# Commonlib.sh: Functions to support all others functions and pocinstaller.sh
# Site        : https://github.com/tiagotarifa/pocinstaller
# Author      : Tiago Tarifa Munhoz
# License     : GPL3
#
#--------/ Description /--------------------------------------------------------
#   This script has functions to handle with loging, create files, and
# other stufs. 
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
# Brazilian shell script yahoo list: shell-script@yahoogrupos.com.br
#   Especially: Julio (below), Itamar (funcoeszz co-author: http://funcoeszz.net)
#	and other 4K users who make this list rocks!
# The brazilian shell script (pope|master) Julio Cezar Neves who made the best
#   portuguese book of shell script (Programação Shell Linux 11ª edição);
#	His page: http://wiki.softwarelivre.org/TWikiBar/WebHome
# Hartmut Buhrmester: Ho rewrite wsusoffline script for Linux. I was inspired 
#   by the way you did your log, and copy some code too.
# Cidinha (my wife): For her patience and love.
# 
#--------/ History /------------------------------------------------------------
# Legend: '-' for features and '+' for corrections
#  Version: 1.0 released in 2017-07-12
#   -Log maker to make a log file with date and levels;
#   -System validation for minimal requirements;
#   ...Many small others
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
WaitingNineSeconds(){ #Print 8 to 0 per second while user wait
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
	echo
}
ValidatingEnvironment(){ #Verify minimal system requirements for Arch
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
MakeAnswerFile(){ #Create a answer file in /tmp with collected data
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
CreateFirstBootScript(){ #USE: CreateFirstBootScript </path/script_model> </path/scriptToMake>
	scriptModel="$1"
	scriptToMake="$2"

	(
	cp "$scriptModel" "$scriptToMake" || return
	sed -i '/readonly FileFirstBootScriptOnTarget/ s/""/"'$scriptToMake'"/
		' "$scriptToMake" || return
	sed -i '/readonly Packages/ s/""/"'$packages'"/
		' "$scriptToMake" || return
	)
	if [ $? -eq 0 ]
	then
		chmod +x "$scriptToMake"
		LogMaker "MSG" "$logStep First boot script created"
	else
		LogMaker "ERR" "$logStep Impossible to create the first boot script."
	fi
}
RunArgumentAsScript(){ #Convert script in a var '$@' and run it.
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
