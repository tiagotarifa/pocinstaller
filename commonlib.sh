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
#--------/For Loggin /----------------------------------------------------------
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
			   echo "${date}${$level}: ${message//\\[nt]/}" >> "$logFile"
			;;
		  ERR) echo -e "---$level: $message.\n    More details in '$logFile'\n\nLeaving out..."
			   cat <<-_eof_ >> "$logFile"
				${date}${level}: ${message//\\[nt]/}
				  Occurred when calling function '${FUNCNAME[1]}' line '${BASH_LINENO[1]}'
				  Functions called in hierarchical order:
				   '${FUNCNAME[*]}'
				_eof_
			;;
	esac
}
#--------/ "Graphical" User Interface Functions /-------------------------------
GuiInputBox(){ #Use: GuiInputBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local cols=0
	local lines=0
	local okLabel="Next"
	local cancelLabel="Back"
	local backTitle="$BackTitle"
	if [ -n "$whereAmI" ] 
	then 
		local hline="--hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+7))
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors					\
		--aspect 80						\
		--stdout $hline					\
		--title "$title"				\
		--inputbox "$text" $lines $cols
}
GuiMessageBox(){ #Use: GuiMessageBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local cols=0
	local lines=0
	local okLabel="Next"
	local cancelLabel="Back"
	local backTitle="$BackTitle"
	local hline
	if [ -n "$whereAmI" ] 
	then 
		local hline="--hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+5))
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors					\
		--aspect 80						\
		--stdout $hline					\
		--title "$title"				\
		--msgbox "$text" $lines $cols
}
GuiYesNo(){ #Use: GuiYesNo "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local lines=0
	local yesLabel="Yes"
	local noLabel="No"
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+6))
	fi
	dialog							\
		--backtitle "$backTitle"	\
		--trim --colors				\
		--yes-label "$yesLabel"		\
		--no-label "$noLabel"		\
		--aspect 80					\
		--stdout $hline				\
		--title "$title"			\
		--yesno "$text" $lines $cols
}
GuiYesNoBack(){ #Use: GuiYesNoBack "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local extraLabel="No"
	local okLabel="Yes"
	local cancelLabel="Back"
	local cols=0
	local lines=0
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+6))
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors					\
		--aspect 80						\
		--extra-button					\
		--extra-label "$extraLabel"		\
		--stdout $hline					\
		--title "$title"				\
		--yesno "$text" $lines $cols
}
GuiChecklist(){ #Use: GuiChecklist "Window's Title" "Text to show" "tag1 [item1] status1 tag2 [item2] status2..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local cols=0
	local okLabel="Next"
	local cancelLabel="Back"

	#Check if 'item' exist and solve the problem
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"

	#Display a status on botton and fix size problem
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		local displayCols=$(tput cols)
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi

	dialog										\
		--backtitle "$backTitle"				\
		--title "$title" $additionalParameter	\
		--ok-label "$okLabel"					\
		--cancel-label "$cancelLabel"			\
		--trim --colors 						\
		--aspect 80								\
		--separate-output						\
		--stdout $hline							\
		--checklist "$text" 0 $cols 0			\
		$list
	case $? in
		0) return 0 ;;
		1) return 1 ;;
		*) LogMaker "ERR" "Dialog exit with error! The parameter was: $list\n" ;;
	esac
}
GuiRadiolist(){ #Use: GuiRadiolist "Window's Title" "Text to show" "tag [item] status tag [item] status..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local cols=0
	local okLabel="Next"
	local cancelLabel="Back"

	#Check if 'item' exist and solve the problem
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"

	#Display a status on botton and fix size problem
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		local displayCols=$(tput cols)
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi

	dialog										\
		--backtitle "$backTitle"				\
		--aspect 80								\
		--ok-label "$okLabel"					\
		--cancel-label "$cancelLabel"			\
		--trim --colors 						\
		--stdout $hline							\
		--title "$title" $additionalParameter	\
		--radiolist "$text" 0 $cols 0 			\
		$list
	case $? in
		0) return 0 ;;
		1) return 1 ;;
		*) LogMaker "ERR" "Dialog exit with error! The parameter was: $list\n" ;;
	esac
}
GuiPasswordBox(){ #Use: GuiPasswordBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local lines=0
	local okLabel="Next"
	local cancelLabel="Back"
	local hline
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		cols=80
		lines=$(($(echo -e "$text" | wc -l)+7))
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--stdout $hline					\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors					\
		--aspect 80						\
		--title "$title"				\
		--passwordbox "$text" $lines $cols
}
GuiSummary(){ #Use: GuiMessageBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local extraButton="Start Again"
	local cols=0
	local lines=0
	local backTitle="$BackTitle"
	local okLabel="Next"
	local hline
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
	dialog							 \
		--backtitle "$backTitle"	 \
		--extra-button				 \
		--extra-label "$extraButton" \
		--ok-label "$okLabel"		 \
		--trim --colors				 \
		--aspect 80					 \
		--stdout $hline				 \
		--title "$title"			 \
		--msgbox "$text" $lines $cols
}
GuiMenu(){ #Use: GuiMenu "Window's Title" "Text to show" "itemMenu [*Description] ..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local okLabel="Next"
	local cancelLabel="Back"

	#Check if 'Description' exist in a bash way
	local toCheck="${list/\**/}"
	local -a check=($toCheck)
	[ "${#check[@]}" -lt 2 ] || local additionalParameter="--no-items"

	#Display a status on botton and fix size problem
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		local displayCols=$(tput cols)
		cols=$displayCols
		[ "$displayCols" -gt 85 ] && cols=85
		[ "$displayCols" -lt 81 ] && cols=80
	fi

	dialog								\
		--backtitle "$backTitle"		\
		--aspect 80						\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--colors						\
		--trim $additionalParameter		\
		--stdout $hline					\
		--title "$title" 				\
		--menu "$text" 0 0 0 			\
	$list
	case $? in
		0) return 0 ;;
		1) return 1 ;;
		*) LogMaker "ERR" "Dialog exit with error! The parameter was: $list\n" ;;
	esac
}
GuiCalendar(){ #Use: GuiCalendar "Window's Title" "Text to show" | Return: '%m%d_%Y'
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local okLabel="Next"
	local cancelLabel="Back"
	local hline
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		cols=80
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--stdout $hline					\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors					\
		--aspect 80						\
		--title "$title"				\
		--date-format '%m%d_%Y'			\
		--calendar "$text" 0 $cols
}
GuiTimeBox(){ #Use: GuiTimeBox "Window's Title" "Text to show" | Return: '%H%M'
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	local cols=0
	local okLabel="Next"
	local cancelLabel="Back"
	local hline
	if [ -n "$whereAmI" ]
	then 
		local hline="--hline $whereAmI"
		cols=80
	fi
	dialog								\
		--backtitle "$backTitle"		\
		--stdout $hline					\
		--ok-label "$okLabel"			\
		--cancel-label "$cancelLabel"	\
		--trim --colors 				\
		--aspect 80						\
		--title "$title"				\
		--time-format '%H%M'			\
		--timebox "$text" 0 $cols
}
GuiIntro(){ #Do not use. In development...
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
#--------/ Auxiliary for getting functions/-------------------------------------
GetUserName(){ #Return: someonename
	local title="User"
	local text="Type the user login name"
	local errorMessage 
	local -l userName
	while [ "$check" != "ok" ]
	do
		errorMessage=""
		userName=$(GuiInputBox "$title" "$text") || return
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
GetPassword(){ #Use: GetPasword "Text" | Return: p@ssw0rd
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
		password1="$(GuiPasswordBox "$title" "$text")" || return
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
		password2="$(GuiPasswordBox "$title" "$strongMessage\n\n$textAgain")" || return
		if [ "$password1" != "$password2" ]
		then
			GuiMessageBox "Error!" "Passwords does not match!\nPlease try again."
			continue
		fi
		check="ok"
	done
	openssl passwd -1 -stdin <<<"$password1"
	LogMaker "LOG" "Collected: password."
}
GetGroups(){ #Return: users,audio,video,games,...
	local title="Groups"
	local text="Select one or more groups for your user"
	local groupList="$(sed 's/\:.*$/ off /' /etc/group)"
	local groups
	while [ -z "$groups" ]
	do
		local groups="$(GuiChecklist "$title" "$text" $groupList)" || return
	done
	groups="$(tr '\n' ',' <<<$groups)"
	echo "${groups%,}"
	LogMaker "LOG" "Collected: groups '$groups'."
}
IsEfi(){ #Returns 0 if it is a EFI system and 1 if its not.
	[ -d "$efiFirmware" ]
}
#--------/ Getting Functions /--------------------------------------------------
GetGrubArguments(){
	if IsEfi
	then
		echo "--target=x86_64-efi --efi-target=${DirBoot##$DirTarget}"
		LogMaker "LOG" "EFI detected."
	else
		echo "--target=i386-pc --boot-directory=${DirBoot##$DirTarget}"
		LogMaker "LOG" "Bios only detected."
	fi
}
GetHostname(){ #Return: mycomputer
	# Validate and return the hostname typed
	# Validation made based on man 8 useradd
	local title="Input a hostname"
	local text="Spaces, dots or special characters is not allowed"
	local check errorMessage hostname 
	while [ "$check" != "ok" ]
	do
		errorMessage=""
		hostname=$(GuiInputBox "$title" "$text") || return
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
	LogMaker "LOG" "Collected: hostname."
}
GetTimezone(){ #Return: America/Sao_Paulo
	local title="Timezone"
	local text="Choose a timezone"
	local dir="/usr/share/zoneinfo"
	local timezoneList="$(find "$dir" -type f -printf '%P off \n' | sort)"
	local timezone
	while [ -z "$timezone" ]
	do
		timezone="$(GuiRadiolist "$title" "$text" $timezoneList)" || return
	done
	echo $timezone
	LogMaker "LOG" "Collected: timezone."
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
	GuiChecklist "$title" "$text" $timezoneList || return
	LogMaker "LOG" "Collected: locale."
}
GetLanguage(){ #Use: GetLanguage locale1 locale2 ... | Return: localeX
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
		language="$(GuiRadiolist "$title" "$text" $param)" || return
	done
	echo ${language%%\#*}
	LogMaker "LOG" "Collected: language."
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
	GuiRadiolist "$title" "$text" $fontList || return
	LogMaker "LOG" "Collected: console font."
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
	GuiRadiolist "$title" "$text" ${fontList//\.uni/''} || return
	LogMaker "LOG" "Collected: font map for console font."
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
		keymap="$(GuiRadiolist "$title" "$text" ${keymapList//.map.gz/})" || return
	done
	keymap="${keymap##*/}"
	loadkeys $keymap
	LogMaker "LOG" "Defined keyboard layout '$keymap' on system."
	echo $keymap
	LogMaker "LOG" "Collected: keyboard layout."
}
GetRepositories(){ #Return: repo1 repo2 repo3 ... [custom->repoCustom]
	local title="Repositories"
	local text="Select one or more repositories next to you"
	local titleCustomRepo="Custom Repository"
	local textCustomRepo="Type your custom repository here:"
	local file="/etc/pacman.d/mirrorlist"
	local repositories
	if grep -q 'Score' $file
	then
		local repoList="$(sed -rn '
			/Server|Score/!d
			/##/ s/^.+, //
			/^[[:alpha:]]/ s/ /_/g
			{h;n;G}
			s/^#?Server = //
			s/$/ off/
			s/\n/ /p
			' $file \
			| sort -k2 \
			| tr '\n' ' ')"
	else
		local repoList="$(sed -rn '
			/^$/,$!d
			/^$/d
			/##/ s/ /_/2g
			s/## //
			{h;n;G}
			s/^#?Server = / /
			s/$/ off/
			s/\n/ /p
			' $file \
			| sort -k2 \
			| tr '\n' ' ')"
	fi
	while [ -z "$repositories" ]
	do
		repositories="$(GuiChecklist "$title" "$text" $repoList)" || return
	done
	LogMaker "LOG" "Collected: repositories."
	echo "$repositories"

}
GetRootPassword(){ #Return: p@ssw0rd
	#Yes! It's necessary!
	#I'm trying to respect rules here!
	echo "root:$(GetPassword "Type a password for root user")"
	LogMaker "LOG" "Collected: root password."
}
GetUsers(){ #Return: -m -s /bin/bash -G users,wheel,games tiago:passwordcrypted
	local titleUser="Users"
	local textUser="Type your user login"
	local titleQuestion="Add user"
	local textQuestion="Do you want to add a ordinary user?"
	local textQuestionAgain="Do you want to add another ordinary user?"
	local count=0
	local user groups 
	local -a users passwords groupList

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
		user="$(GetUserName)" || return
		groups="$(GetGroups)" || return
		groupList[$count]="$groups"
		passwords[$count]="$(GetPassword "Type a password for '$user'")" \
			|| return
		users[$count]="-m -s /bin/bash -G $groups $user"
		let ++count
	done
	for ((count=0;count<${#users[@]};count++))
	do
		echo "${users[$count]}:${passwords[$count]}"
		LogMaker "LOG" "Collected: User '${users[$count]##* }', groups '${groupList[$count]}' and password for it."
	done
}
GetMultilib(){ #Return: yes or no
	local title="Multilib"
	local text="Do you want to enable a multilib install?"
	GuiYesNoBack "$title" "$text"
	case $? in
		0) echo yes ;;
		1) return 1	;;
		3) echo no	;;
	esac
	LogMaker "LOG" "Collected: multilib option."
}
GetProfiles(){ #Return: /path/nameOfProfile.cfg
	local title="Profiles"
	local text="Select 'Only Base Package' to install only basic 
		packages (pacman -S base) or a pre-defined profile"
	local dir="${BaseAnswerFile%/*}/"
	local profiles="$(find "$dir" 					\
		-type f 									\
		-iname "*.cfg" 								\
		-printf '%P;' 								\
		-exec grep -Eo -m1 'escription: .*' {}	\;	\
		| sort )"
	local profile
	#Replacing in a bash way
	profiles="${profiles//.cfg/}"			#remove .cfg from name of files
	profiles="${profiles//escription:/}"	#remove garbage 'escription:'
	profiles="${profiles// /_}"				#replace ' ' '_'
	profiles="${profiles//;_/ *}"			#replace ';_' ' *' if exist
	profiles="${profiles//;/ *}"			#replace ';' ' *' if exist
	
	profile="$(GuiMenu "$title" "$text" $profiles).cfg" \
		|| return
	echo "${dir}$profile"
	LogMaker "LOG" "Collected: profile option."
}
GetSummary(){ #Display all data collected
	local title="All data collected"
	local text="Verify that the data is correct before continuing:"
	local usersAndGroups="$(
		sed -r '
			s/^.+-G ([[:alpha:]].+) ([[:alpha:]].+)/    User: \2   Groups: \1 \\n/
			' <<<"$usersList")"
	local locale="$( 
		sed '
			:a;N;$!ba
			s/\n/\\n    /g
			s/#/ /g
			'<<<"$locale")"
	local summary="$(cat <<-_eof_
		\\ZbHostname:\\ZB $hostname \n
		\\ZbTimezone:\\ZB $timezone \n
		\\ZbLanguage:\\ZB $language \n
		\\ZbKeymap:\\ZB $keymap \n
		\\ZbMultilib:\\ZB $multilib \n
		\\ZbLocale:\\ZB \n
		    $locale \n
		\\ZbRepositories:\\ZB \n
		    $(sed '
				:a;N;$!ba
				s/\n/\\n    /g ; s/#/ /g' <<<"$repositories") \n
		\\ZbUsers and Groups:\\ZB \n
		$usersAndGroups \n
		\\ZbProfile selected:\\ZB $profile
	_eof_
	)"
	GuiSummary "$title" "$text\n\n$summary" > /dev/null 2>&1 || return
	LogMaker "LOG" "The summary was displayed."
}
#--------/ Auxiliary for setting functions/-------------------------------------
GetEthernetDevice(){ #Return: enp2s0 or eth0 or any network device
	local title="Ethernet card"
	local text="Configuration of ethernet card"
	# TODO: Make a better sed code here
	local wifiDevFilter="$(sed '
		s/.*net\///
		s/\/.*$/\|/
		' <<<"$(ls -d /sys/class/net/*/wireless 2> /dev/null)")"
	local ethernetList="$(sed -r '
			/^[[:alnum:]]+:/!d
			s/(^[[:alnum:]]+):.*/\1/
			' /proc/net/dev \
			| grep -v "${wifiDevFilter%|}")"
	if [ "$(wc -l <<<"$ethernetList")" -lt 2 ] 
	then 
		echo "${ethernetList/ off/}"
	else
		GuiMenu "$title" "$text" $ethernetList || return
	fi
}
GetWifiDevice(){ #Return: wlp2s0 or eth1 or any wireless device
	local title="Wireless card"
	local text="Configuration of wireless card"
	local wifiDevList="$(ls -d /sys/class/net/*/wireless 2> /dev/null)"
	local gb1 gb2 gb3 wifi gb4
	if [ "$(wc -l <<<"$wifiDevList")" -gt 2 ] 
	then 
		while IFS=/ read gb1 gb2 gb3 wifi gb4
		do
			$wifiDevList="$wifiDevList $wifi off"
		done <<<"$wifiDevList"
		GuiMenu "$title" "$text" $wifiDevList || return
	else
		wifiDevList="${wifiDevList#*net/}"
		echo "${wifiDevList%/*}"
	fi
}
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
#--------/ Setting Functions /--------------------------------------------------
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
		LogMaker "LOG" "Network: There is no internet conection. Trying to configure network..."
		[ -n "$textMode" ] && return 0

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
		LogMaker "LOG" "DateAndTime: It's not possible to automatic update your system clock!"
		[ -n "$textMode" ] && return 0

		date="$(GuiCalendar "$title" "$text")" || return
		time="$(GuiTimeBox "$title" "$text")"  || return
		date "${date%_*}${time}${date#*_}"	   || return
		hwclock -w							   || return
		LogMaker "LOG" "DateAndTime: date and time manualy defined!"
	fi
}
#--------/ Answer file /--------------------------------------------------------
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
}
#--------/ Checking Functions /-------------------------------------------------
ValidatingEnvironment(){
	local title="Environment Validation"
	local text="Checking if everything is ok:"
	local memorySize="$MachineMemSize"
	local dirTarget="$DirTarget"
	local dirBoot="$DirBoot"
	local mountedRootDir="$MountedRootDir"
	local mountedBootDir="$MountedBootDir"
	local swap="$SwapActive"
	local textMode="$1"
	local efiFirmware="$EfiFirmware"

	local errorText
	#Memory
	if [ "$memorySize" -lt 524288 ]
	then
		text="$text\n* Memory \Z1low\Z0: $memorySize"
	else
		text="$text\n* Memory ok: $memorySize"
	fi
	#Is partition mounted for root installation?
	if [ "$mountedRootDir" == "$dirTarget" ]
	then
		text="$text\n* Root partition is mounted in '$dirTarget'."
		#Root partition size
		if [ "${PartitionRootSize%M}" -lt 800 ]
		then
			errorText="$errorText\n* Partition root with insufficient size: 
				${PartitionRootSize##* }.\nMinimal is 800MB"
		else
			text="$text\n* Partition root size ok: ${PartitionRootSize##* }"
		fi
	else
		errorText="$errorText\n* Have you mounted your root partition in '$dirTarget' ?"
	fi
	#Is partition mounted for /boot?
	if [ "$mountedBootDir" == "$dirBoot" ]
	then
		text="$text\n* Boot partition is mounted in '$dirBoot'."
		#Boot partition size
		if [ "${PartitionBootSize%M}" -lt 100 ]
		then
			errorText="$errorText\n* Partition boot with insufficient size:
			${PartitionBootSize##* }.\n Minimal is 100MB"
		else
			text="$text\n* Partition boot size ok: ${PartitionBootSize##* }"
		fi
	else
		errorText="$errorText\n* Have you mounted your boot partition in '$dirBoot' ?"
	fi
	#Is there a active swap?
	if [ -n "$swap" ]
	then
		text="$text\n* Swap is on in $swap"
	else
		text="$text\n* \Z1Have you activated you swap partition?\Z0"
	fi
	#Bios or EFI?
	if IsEfi
	then
		text="$text\n* It has a EFI support"
	else
		text="$text\n* It has a bios support only"
	fi
	if [ -n "$errorText" ]
	then
		if [ -n "$textMode" ]
		then
			LogMaker "ERR" "SystemCheck: Some requirements have not been met:\n$errorText"
		else
			GuiMessageBox "$title" "$text\n$errorText"
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
		else
			GuiMessageBox "$title" "$text"
			LogMaker "LOG" "SystemCheck: $text"
		fi
	fi
}

