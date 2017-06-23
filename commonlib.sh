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
#--------/ Functions /----------------------------------------------------------

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
GuiChecklist() { #Use: GuiChecklist "Window's Title" "Text to show" "dialog list"
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--single-quoted				\
		--title "$title"			\
		--checklist "$text" 0 0 0 	\
		$list
}
GuiRadiolist() { #Use: GuiInputBox "Window's Title" "Text to show" "dialog list"
	local title="$1"
	local text="$2"
	shift 2
	local list="$@"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--radiolist "$text" 0 0 0 	\
		$list
}
GuiPasswordBox() { #Use: GuiInputBox "Window's Title" "Text to show"
	local title="$1"
	local text="$2"
	local backTitle="$BackTitle"
	dialog							\
		--backtitle "$backTitle"	\
		--stdout					\
		--title "$title"			\
		--passwordbox "$text" 0 0
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
