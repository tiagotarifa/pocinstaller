#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# GetFunctions.sh: Functions to get data from user or system, validate them and
#                  use it on pocinstaller.sh
# Site           : https://github.com/tiagotarifa/pocinstaller
# Author         : Tiago Tarifa Munhoz
# License        : GPL
#
#--------/ Description /--------------------------------------------------------
#   It has functions that get data and validate it. I.e.
# -GetHostname will get the string typed by user and verify if it' respect the 
# rules of a hostname name (less than 64 chars, no dots, etc)
# -GetPassword will check the power of the password typed.
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
# Hartmut Buhrmester: Ho rewrite wsusoffline script for Linux. I I was inspired 
#   by the way you did your log, and copy some code too.
# Cidinha (my wife): For her patience and love.
# 
#--------/ History /------------------------------------------------------------
# Legend: '-' for features and '+' for corrections
#  Version: 1.0 released in 2017-07-12
#   -Validate information like hostname and passwords;
#   -Summary suport with GetSummary;
#   -Profiles support with GetProfiles;
#   -Detect what kind of mirrolist file (livecd or installed system) and handle it;
#   -Loggin support;
#   -Many others...
#--------/ Auxiliary for GetUsers and GetRootPassword/-------------------------------
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
		strongMessage="Password Strength: \ZbVery Strong\ZB"
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
				1) strongMessage="Password Strength: \ZbStrong\ZB"			 ;;
				2) strongMessage="Password Strength: \ZbMedium\ZB"			 ;;
				*) strongMessage="Password Strength: \ZbA piece of crap!\ZB" ;;
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
}
#--------/ Getting data from system/-------------------------------------------------
GetGrubArguments(){ #Return grub parameters according to system (Efi or Bios) 
	if IsEfi
	then
		echo "--target=x86_64-efi --efi-target=${DirBoot##$DirTarget}"
		LogMaker "LOG" "EFI detected."
	else
		echo "--target=i386-pc --boot-directory=${DirBoot##$DirTarget}"
		LogMaker "LOG" "Bios only detected."
	fi
}
GetMkinitcpioLvmHook() { #Return 'sed' command to add lvm support on /etc/mkinitcpio.conf
	if [ "$(pvs | wc -l)" -gt 1 ] 
	then
		echo "/^HOOKS=/ s/block/block lvm2/;"
	fi
}
GetMkinitcpioRaidHook(){ #Return 'sed' command to add mdadm support on /etc/mkinitcpio.conf
	if [ -e /proc/mdstat ] 
	then
		echo "/^HOOKS=/ s/block/block mdadm/;"
	fi
}
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
#--------/ Getting data from users/--------------------------------------------------
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
	local dirProfiles="${DirProfiles%/*}/"
	local profiles="$(find "$dirProfiles"			\
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
	echo "${dirProfiles}$profile"
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
		\\ZbMultilib:\\ZB $multilib \n
		\\ZbKeymap:\\ZB $keymap \n
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
#--------/ Not yet implemented/-----------------------------------------------------
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
