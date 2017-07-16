#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# GuiFunctions.sh: Functions to interact with user using a third software like
#                  dialog. It's part of Piece of Cake Installer
# Site           : https://github.com/tiagotarifa/pocinstaller
# Author         : Tiago Tarifa Munhoz
# License        : GPL3
#
#--------/ Description /--------------------------------------------------------
#   Functions to interact with user and take data like hostname, repositories, etc.
#   All of then was made using 'dialog'.
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
#  Legend: '-' for features and '+' for corrections
#    Version: 1.0 released in 2017-07-09
#     -Support to colors (see dialog's man);
#     -Only show help line(--hline) if is need it;
#     -Detect if lists has 2 or 3 itens and handle with that;
#     -Handle with terminal size (lines and columms);
#    TODO:
#     -Finish GuiIntro function;
#     -Add translate support;
#-------------------------------------------------------------------------------
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
#--------/ Not implemented /----------------------------------------------------
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
