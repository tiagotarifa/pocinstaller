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
#  Version: 1.0 released in 2017-07-12
#   -Network functions to fix IP and DHCP;
#   -Set up grub according by system I.e: Efi(x86_64) or bios(x86)
#   ...Many small others
#--------/ Ordinary functions /-------------------------------------------------
readonly PreInitialScript="/root/preinitial.sh"
readonly PosInitialScript="/root/posinitial.sh"
readonly Step="SystemInstallation 11:"
readonly FileFirstBootScriptOnTarget=""
readonly Packages=""
LogMaker() { #Use: <MSG|LOG|WAR|ERR> <Message>
	local logFile="/var/log/pocinstaller.log"
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
PreInitial(){
	local script="$PreInitialScript"
	LogMaker "MSG" "$Step Running Pre script ..."
	if [ -s "$script" ]
	then
		$script \
			&& LogMaker "MSG" "$Step Script execution has been done." \
			|| LogMaker "ERR" "$Step Script returned with error. Exiting..."
	fi
}
PosInitial(){
	local script="$PosInitialScript"
	LogMaker "MSG" "$Step Running Pos script ..."
	if [ -s "$script" ]
	then
		$script \
			&& LogMaker "MSG" "$Step Script execution has been done." \
			|| LogMaker "ERR" "$Step Script returned with error. Exiting..."
	fi
}
Installation(){
	pacman -Sy "$Packages" \
		&& LogMaker "LOG" "$Step Installation packages has been finish!" \
		|| LogMaker "ERR" "$Step Impossible to install packages!" \"
}
Finishing(){
	LogMaker "LOG" "$Step Finishing installation!"
	systemctl disable pocinstaller
	LogMaker "LOG" "$Step Rebooting...!"
	rm "$FileFirstBootScriptOnTarget" "$PreInitialScript" "$PosInitialScript"
	shutdown -r now
}
LogMaker "LOG" "$Step Starting Stage 'Finishing installation'!"
PreInitial
Installation
PosInitial
Finishing
