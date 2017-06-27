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
GuiInputBox() { #Use: GuiInputBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--inputbox "$text" 0 0
}
GuiMessageBox() { #Use: GuiMessageBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--msgbox "$text" 0 0
}
GuiYesNo() { #Use: GuiYesNo "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--yesno "$text" 0 0
}
GuiChecklist() { #Use: GuiChecklist "Window's Title" "Text to show" "tag1 [item1] status1 tag2 [item2] status2..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	#set -x
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"
	dialog										\
		--backtitle "$backTitle"				\
		--title "$title" $additionalParameter	\
		--stdout								\
		--single-quoted							\
		--checklist "$text" 0 0 0 				\
		$list
	#set +x
}
GuiRadiolist() { #Use: GuiRadiolist "Window's Title" "Text to show" "tag [item] status tag [item] status..."
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	local toCheck="${list%%off*}"
	local -a check=($toCheck)
	local additionalParameter
	[ "${#check[@]}" -lt 2 ] && additionalParameter="--no-items"
	dialog										\
		--backtitle "$backTitle"				\
		--stdout								\
		--title "$title" $additionalParameter	\
		--radiolist "$text" 0 0 0 				\
		$list
}
GuiMenu() { #Use: GuiInputBox "Window's Title" "Text to show" "dialog list"
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
GuiPasswordBox() { #Use: GuiPasswordBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--passwordbox "$text1" 0 0
}
GuiIntro() {
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
#--------/ Auxiliary functions/-------------------------------
GetUserName() { #Return Ex.: someonename
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
GetPassword() { #Use: GetPasword "Text" | Return Ex.: p@ssw0rd
	local title="Password"
	local text1="$@"
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
		grep -E '[[:punct:]].+[[:punct:]].+[[:punct:]]' <<<"$password1" \
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
GetGroups(){ #Return Ex.: users,audio,video,games,...
	local title="Groups"
	local text="Select one or more groups for your user"
	local groupList="$(sed 's/\:.*$/ off /' /etc/group)"
	local groups="$(GuiChecklist "$title" "$text" $groupList)"
	echo ${groups// /,}
}
