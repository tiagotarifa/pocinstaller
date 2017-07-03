#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# commonlib.sh: Auxiliar functions to pocinstaller.sh
#
# Site		: https://github.com/tiagotarifa/pocinstaller
# Author	: Tiago Tarifa Munhoz
# License	: GPL
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
#--------/ History /------------------------------------------------------------
#    Under development
#
#--------/ "Graphical" User Interface Functions /-------------------------------
GuiInputBox(){ #Use: GuiInputBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local cols=0
	local lines=0
	local backTitle="$BackTitle"
	if [ -n "$whereAmI" ] 
	then 
		local hline="--colors --hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+7))
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--aspect 80					\
		--stdout $hline				\
		--title "$title"			\
		--inputbox "$text" $lines $cols
}
GuiMessageBox(){ #Use: GuiMessageBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local cols=0
	local lines=0
	local hline
	local backTitle="$BackTitle"
	if [ -n "$whereAmI" ] 
	then 
		local hline="--colors --hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+5))
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--aspect 80					\
		--stdout $hline				\
		--title "$title"			\
		--msgbox "$text" $lines $cols
}
GuiYesNo(){ #Use: GuiYesNo "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local lines=0
	if [ -n "$whereAmI" ]
	then 
		local hline="--colors --hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+6))
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--aspect 80					\
		--stdout $hline				\
		--title "$title"			\
		--yesno "$text" $lines $cols
}
GuiChecklist(){ #Use: GuiChecklist "Window's Title" "Text to show" "tag1 [item1] status1 tag2 [item2] status2..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local cols=0

	#Check if 'item' exist and solve the problem
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"

	#Display a status on botton and fix size problem
	if [ -n "$whereAmI" ]
	then 
		local hline="--colors --hline $whereAmI"
		local displayCols=$(tput cols)
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi

	dialog										\
		--backtitle "$backTitle"				\
		--title "$title" $additionalParameter	\
		--aspect 80								\
		--stdout $hline							\
		--single-quoted							\
		--checklist "$text" 0 $cols 0			\
		$list
}
GuiRadiolist(){ #Use: GuiRadiolist "Window's Title" "Text to show" "tag [item] status tag [item] status..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local cols=0

	#Check if 'item' exist and solve the problem
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"

	#Display a status on botton and fix size problem
	if [ -n "$whereAmI" ]
	then 
		local hline="--colors --hline $whereAmI"
		local displayCols=$(tput cols)
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi

	dialog											\
		--backtitle "$backTitle"					\
		--aspect 80									\
		--stdout $hline								\
		--title "$title" $additionalParameter		\
		--radiolist "$text" 0 $cols 0 				\
		$list
}
GuiPasswordBox(){ #Use: GuiPasswordBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local lines=0
	local hline
	if [ -n "$whereAmI" ]
	then 
		local hline="--colors --hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+7))
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--stdout $hline				\
		--aspect 80					\
		--title "$title"			\
		--passwordbox "$text" $lines $cols
}
GuiSummary(){ #Use: GuiMessageBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local extraButton="Start Again"
	local cols=0
	local lines=0
	local hline
	local backTitle="$BackTitle"
	if [ -n "$whereAmI" ] 
	then 
		local hline="--hline $whereAmI"
		local displayCols=$(tput cols)
		local displayLines=$(tput lines)
		lines="$(echo -e "$text" | wc -l)"
		[ $lines -gt $displayLines ] && lines=$displayLines
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--extra-button				\
		--extra-label "$extraButton" \
		--colors					\
		--aspect 80					\
		--stdout $hline				\
		--title "$title"			\
		--msgbox "$text" $lines $cols
}
GuiMenu(){ #Use: GuiInputBox "Window's Title" "Text to show" "dialog list"
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--no-tags					\
		--title "$title"			\
		--menu "$text" 0 0 0 		\
	$list
}
GuiIntro(){
	local text="Bem vindo"
	local col=10
	local lines=$(tput lines)

	clear
	for ((i=0;i<$lines;i++))
	do
		tput cup $((i-1)) $col
		tput dch ${#text}
		tput cup $i $col 
		printf "$text"
		sleep 1
	done
}
#--------/ Auxiliary functions/-------------------------------------------------
GetUserName(){ #Return: someonename
	local title="User"
	local text="Type the user login name"
	local errorMessage 
	local -l userName
	while [ "$check" != "ok" ]
	do
		errorMessage=""
		userName=$(GuiInputBox "$title" "$text") || return 1
		[ "${#userName}" -gt 32 ] 														\
			&& errorMessage="* It can't be more than 32 chars"	
		[ -z "${userName}" ]	 														\
			&& errorMessage="* It can't be empty"	
		grep -Eqs '[[:blank:]]' <<<"$userName" 											\
			&& errorMessage="${errorMessage}\n* Spaces is not allowed"
		grep -Eqs '[[:punct:]]' <<<"$userName" 											\
			&& errorMessage="${errorMessage}\n* Punctuation marks is not allowed"
		grep -Eqs 'á|Á|à|À|ã|Ã|â|Â|é|É|ê|Ê|ü|Ü|í|Í|ó|Ó|õ|Õ|ô|Ô|ú|Ú|ç|Ç' <<<"$userName" 	\
			&& errorMessage="${errorMessage}\n* Accented letter is not allowed"
		if [ -n "$errorMessage" ]
		then
			errorMessage="The rules for setting user name must be respected:\n$errorMessage"
			GuiMessageBox "Error" "$errorMessage"
		else
			GuiYesNo "Your user name will be:" "\n'$userName'\n\nContinue?" && check="ok"
		fi
	done
	echo $userName
}
GetPassword(){ #Use: GetPasword "Text" | Return Ex.: p@ssw0rd
	local title="Password"
	local text="$@"
	local textAgain="Type again..."
	local warnTitle="Alert! Weak password"
	local warnText="Do you want to continue?"
	
	local check password1 password2 warnMessage strong strongMessage
	while [ "$check" != "ok" ]
	do
		strongMessage="Password Strength: Very Strong"
		password1="" password2="" warnMessage=""
		password1="$(GuiPasswordBox "$title" "$text")" || return 1
		if [ -z "$password1" ]
		then
			GuiMessageBox "Error!" "Password can't be empty!\nPlease try again."
			continue
		fi
		[ "${#password1}" -lt 5 ] \
			&& warnMessage="* Less than five chars\n"
		grep -qE '[[:punct:]].*[[:punct:]].*[[:punct:]]' <<<"$password1" \
			|| warnMessage="${warnMessage}* There is no or to few special chars\n"
		grep -qE '[[:lower:]].*[[:lower:]].*[[:lower:]]' <<<"$password1" \
			|| warnMessage="${warnMessage}* There is no or to few lower case\n"
		grep -qE '[[:upper:]].*[[:upper:]].*[[:upper:]]' <<<"$password1" \
			|| warnMessage="${warnMessage}* There is no or to few upper case\n"
		grep -qE '[[:digit:]].*[[:digit:]].*[[:digit:]]' <<<"$password1" \
			|| warnMessage="${warnMessage}* There is no or to few numbers\n"
		if [ -n "$warnMessage" ]
		then
			strong=$(echo -e $warnMessage | wc -l)
			case $strong in
				1) strongMessage="Password Strength: Strong"			;;
				2) strongMessage="Password Strength: Medium"			;;
				*) strongMessage="Password Strength: A piece of crap!"	;;
			esac
			GuiYesNo "$warnTitle" "$strongMessage\n\n${warnMessage}\n${warnText}" \
				|| continue
		fi
		password2="$(GuiPasswordBox "$title" "$strongMessage\n\n$textAgain")" || return 1
		if [ "$password1" != "$password2" ]
		then
			GuiMessageBox "Error!" "Passwords does not match!\nPlease try again."
			continue
		fi
		check="ok"
	done
	openssl passwd -1 -stdin <<<"$password1"
}
GetGroups(){ #Return: users,audio,video,games,...
	local title="Groups"
	local text="Select one or more groups for your user"
	local groupList="$(sed 's/\:.*$/ off /' /etc/group)"
	local groups
	while [ -z "$groups" ]
	do
		local groups="$(GuiChecklist "$title" "$text" $groupList)" || return 1
	done
	echo ${groups// /,}
}
#--------/ Getting Functions /--------------------------------------------------
GetHostname(){ #Return: mycomputer
	# Validate and return the hostname typed
	# Validation made based on man 8 useradd
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
			GuiYesNo "Hostname" "Your hostname will be '$hostname'\nContinue?" && check="ok"
		fi
	done
	echo "$hostname"
}
GetTimezone(){ #Return: America/Sao_Paulo
	local title="Timezone"
	local text="Choose a timezone"
	local dir="/usr/share/zoneinfo"
	local timezoneList="$(find "$dir" -type f -printf '%P off \n' | sort)"
	local timezone
	while [ -z "$timezone" ]
	do
		timezone="$(GuiRadiolist "$title" "$text" $timezoneList)" || return 1
	done
	echo $timezone
}
GetLocale(){ #Return: 'aa_ER@saaho#UTF-8' 'ak_GH#UTF-8' 'an_ES#ISO-8859-15'
	# It's change ' ' to '#' in locales names. It's easier to keep in bash
 	# environment. SetLocale will handle with that.
	local title="Locales"
	local text="Choose more than one locale if you need it"
	local file="/etc/locale.gen"
	local timezoneList="$(sed -r '
		/^#?[a-z]/!d 
		s/^#//
		s/  $//
		s/ /#/g
		s/$/ off /
		' "$file")"
	GuiChecklist "$title" "$text" $timezoneList	|| return 1
}
GetLanguage(){ #Use: GetLanguage 
	local title="Language"
	local text="Set a language for your system.\n(It's based on your locale choice)"
	local locales="$1"
	local temp param language
	for temp in $locales
	do
		param="$param $temp off"
	done
	while [ -z "$language" ]
	do
		language="$(GuiRadiolist "$title" "$text" $param)" || return 1
	done
	echo $language
}
GetConsoleFont(){ #Return: lat7a-16
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
GetConsoleFontMap(){ #Return: cp737
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
GetKeymap(){ #Return: br-abnt2
	local title="Keyboard layout"
	local text="Select a layout for your keyboard"
	local dir="/usr/share/kbd/keymaps"
	local keymap
	local keymapList="$(find "$dir" 		\
		-type f 							\
		-iname "*.map.gz" 					\
		-printf '%P off \n' 				\
		| sort )"
	while [ -z "$keymap" ]
	do
		keymap="$(GuiRadiolist "$title" "$text" ${keymapList//.map.gz/})" || return 1
	done
	echo ${keymap##*/}
}
GetRepositories(){ #Return: repo1 repo2 repo3 ...
	local title="Repositories"
	local text="Select one or more repositories next to you"
	local file="/etc/pacman.d/mirrorlist"
	local repositories
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
	while [ -z "$repositories" ]
	do
		repositories="$(GuiChecklist "$title" "$text" $repoList)" || return 1
	done
	echo $repositories
}
GetRootPassword(){ #Return: p@ssw0rd
	#Yes! It's necessary!
	#I'm trying to respect rules here!
	echo "root:$(GetPassword "Type a password for root user")"
}
GetUsers(){ #Return: -m -s /bin/bash -G users,wheel,games tiago password='p@ssw0rd'
	local titleUser="Users"
	local textUser="Type your user login"
	local titleQuestion="Add user"
	local textQuestion="Do you want to add a ordinary user?"
	local textQuestionAgain="Do you want to add another ordinary user?"
	local count=0
	local user groups 
	local -a users passwords

	while :
	do
		user="" groups=""
		if [ "$count" -eq 0 ]
		then 
			GuiYesNo "$titleQuestion" "$textQuestion" \
				|| break
		else
			GuiYesNo "$titleQuestion" "$textQuestionAgain" \
				|| break
		fi
		user="$(GetUserName)"
		groups="$(GetGroups)"
		passwords[$count]="$(GetPassword "Type a password for '$user'")"
		users[$count]="-m -s /bin/bash -G $groups $user"
		let ++count
	done
	for ((count=0;count<${#users[@]};count++))
	do
		echo "${users[$count]}:${passwords[$count]}"
	done
}
GetSummary(){ #Display all data collected
	local title="All data collected"
	local text="Verify that the data is correct before continuing:"
	local usersAndGroups="$(
		sed -r '
			s/^.+-G ([[:alpha:]].+) ([[:alpha:]].+):.*/    User: \2   Groups: \1 \\n/
			' <<<"$usersList")"
	local localesToShow="$( 
		sed -r '
			s/ /\\n    /g
			s/#/ /g
			'<<<"$locale")"
	local summary="$(cat <<-_eof_
		\\ZbHostname:\\ZB $hostname \n
		\\ZbTimezone:\\ZB $timezone \n
		\\ZbLanguage:\\ZB $language \n
		\\ZbKeymap:\\ZB $keymap \n
		\\ZbLocale:\\ZB \n
		    $localesToShow \n
		\\ZbRepositories:\\ZB \n
		    $(sed 's/ /\\n    /g ; s/#/ /g ;' <<<"$repositories") \n
		\\ZbUsers and Groups:\\ZB \n
		$usersAndGroups \n
	_eof_
	)"
	GuiSummary "$title" "$text\n$summary" > /dev/null 2>&1
}
