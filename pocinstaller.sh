#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# pocinstaller.sh: Manual or automátic installer for Archlinux (under development)
#
# Site		: https://github.com/tiagotarifa/pocinstaller
# Author	: Tiago Tarifa Munhoz
# License	: GPL
#
#--------/ Description /--------------------------------------------------------
#     Peace of Cake installer aims to be a easy and fast installer for Arch 
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
#    Under development
#
#--------/ Loading libraries /--------------------------------------------------
. commonlib.sh
#--------/ Constants /----------------------------------------------------------
readonly BackTitle="Piece of Cake Installer"
#--------/ Getting Functions /--------------------------------------------------
GetHostname(){
	local title="Input a hostname"
	local text="Spaces, dots or special characters is not allowed"
	local check errorMessage hostname 
	while [ "$check" != "ok" ]
	do
		errorMessage=""
		hostname=$(GuiInputBox "$title" "$text") || return 1
		[ "${#hostname}" -gt 64 ] 														\
			&& errorMessage="* It can't be more than 64 chars"	
		[ -z "${hostname}" ]	 														\
			&& errorMessage="* It can't be empty"	
		grep -Eqs '[[:blank:]]' <<<"$hostname" 											\
			&& errorMessage="${errorMessage}\n* Spaces is not allowed"
		grep -Eqs '[[:punct:]]' <<<"$hostname" 											\
			&& errorMessage="${errorMessage}\n* Punctuation marks is not allowed"
		grep -Eqs 'á|Á|à|À|ã|Ã|â|Â|é|É|ê|Ê|ü|Ü|í|Í|ó|Ó|õ|Õ|ô|Ô|ú|Ú|ç|Ç' <<<"$hostname" 	\
			&& errorMessage="${errorMessage}\n* Accented letter is not allowed"
		if [ -n "$errorMessage" ]
		then
			errorMessage="The rules for setting hostname must be respected:\n$errorMessage"
			GuiMessageBox "Error" "$errorMessage"
		else
			GuiYesNo "Your hostname will be:" "\n'$hostname'\n\nContinue?" && check="ok"
		fi
	done
	echo "$hostname"
}
GetTimeZone() {
	local title="Repositories"
	local text="Choose a repository next to you"
	local dir="/usr/share/zoneinfo"
	local timezoneList="$(find "$dir" -type f -printf '%P off \n' | sort)"
	GuiRadiolist "$title" "$text" $timezoneList	|| return 1
}
GetLocale() { #Return Ex.: 'aa_ER@saaho#UTF-8' 'ak_GH#UTF-8' 'an_ES#ISO-8859-15'
	# GetLocale change ' ' to '#' in locales names. It's easier to keep in bash
 	# environment. SetLocale will handle with that.
	local title="Locales"
	local text="Choose more than one locale if you need it"
	local file="/etc/locale.gen"
	local timezoneList="$(sed -r '
		/^#[a-z]/!d 
		s/^#//
		s/  $//
		s/ /#/g
		s/$/ off /
		' "$file")"
	GuiChecklist "$title" "$text" $timezoneList	|| return 1
}
GetConsoleFont(){ #Return Ex.: lat7a-16
	local title="Console Fonts"
	local text="Select a font for your console (It's not for Xorg)"
	local dir="/usr/share/kbd/consolefonts/"
	local fontList="$(find "$dir" 	\
		-maxdepth 1					\
		-type f 					\
		-iname "*.gz" 				\
		-printf '%P off \n' \
		| sort | sed -r 's/(.psfu?|.cp)?.gz//')"
	GuiRadiolist "$title" "$text" $fontList
}
GetConsoleFontMap(){ #Return Ex.: cp737
	local title="Console Font Map"
	local text="Select a Map for your font(It's not for Xorg)"
	local dir="/usr/share/kbd/unimaps/"
	local fontList="$(find "$dir" 	\
		-maxdepth 1					\
		-type f 					\
		-iname "*.uni" 				\
		-printf '%P off \n' \
		| sort)"
	GuiRadiolist "$title" "$text" ${fontList//\.uni/''}
}
GetKeymap() { #Return Ex.: br-abnt2
	local title="Keyboard layout"
	local text="Select a layout for your keyboard"
	local dir="/usr/share/kbd/keymaps"
	local keymapList="$(find "$dir" 		\
		-type f 							\
		-iname "*.map.gz" 					\
		-printf '%P off ' 					\
		| sort )"
	local keymap="$(GuiRadiolist "$title" "$text" ${keymapList//.map.gz/})"
	echo ${keymap##*/}
}
GetRepositories() { #Return Ex.: repo1 repo2 repo3 ...
	local title="Repositories"
	local text="Select a repositórie next to you"
	local file="/etc/pacman.d/mirrorlist"
	local repoList="$(sed -rn '
		/Server|Score/!d
		h
		n
		G
		s/\n/ /
		s/#?Server = http:\/\///
		s/ /_/5g
		s/$/ off / 
		s/\/\$repo.+,//p 
		' $file | sort -k2)"		#Sort by country
	GuiChecklist "$title" "$text" $repoList
	#echo "$repoList"
}
GetRootPassword() {
	local title="Root password"
	local text1="Type password for your root system"
	local text2="Type again..."
	local warnTitle="Alert! Weak password"
	local warnText="Do you want to continue?"
	local check password1 password2 warnMessage
	while [ "$check" != "ok" ]
	do
		password1="$(GuiPasswordBox "$title" "$text1")" || return 1
		password2="$(GuiPasswordBox "$title" "$text2")" || return 1
		if [ "$password1" != "$password2" ]
		then
			GuiMessageBox "Error!" "Passwords does not match!\nPlease try again."
			continue
		fi
		[ "${#password1}" -lt 5 ] \
			&& warnMessage="* Less than five chars\n"
		grep -E '[[:punct]].+[[:punct:]].+[[:punct:]]' <<<"$password1" \
			|| warnMessage="${warnMessage}* There is no or to few special chars\n"
		if [ -n "$warnMessage" ]
		then
			GuiYesNo "$warnTitle" "${warnMessage}${warnText}" \
				|| continue
		fi
		check="ok"
	done
	echo $password1
}
