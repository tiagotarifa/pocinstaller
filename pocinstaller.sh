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
#--------/ Menu /--------------------------------------------------
CollectingDataFromMenu(){
	local step=Hostname
	local -x hostname timezone locale keymap consoleFont consoleFontMap
	local -x repositories rootPassword usersList language whereAmI

	while :
	do
		whereAmI="Hostname-Timezone-Locale-Language-Keymap-Repositories-Root_Password-Users\Zn"
		case $step in
			Hostname) whereAmI="${whereAmI/Hostname/\\Z1Hostname\\Z3}"
					  if hostname="$(GetHostname)"
					  then
					      step=Timezone
					  else
						  return 1
					  fi
					  ;;
		    Timezone) whereAmI="${whereAmI/Timezone/\\Z1Timezone\\Z3}"
					  if timezone="$(GetTimezone)"
					  then 
						  step=Locale
					  else
						  step=Hostname
					  fi
					  ;;
			  Locale) whereAmI="${whereAmI/Locale/\\Z1Locale\\Z3}"
					  if locale="$(GetLocale)"
				  	  then
					      step=Language
					  else
						  step=Timezone
					  fi
					  ;;
			Language) whereAmI="${whereAmI/Language/\\Z1Language\\Z3}"
					  if language="$(GetLanguage "$locale")"
				  	  then
					      step=Keymap
					  else
						  step=Locale
					  fi
					  ;;
		      Keymap) whereAmI="${whereAmI/Keymap/\\Z1Keymap\\Z3}"
					  if keymap="$(GetKeymap)"
				  	  then
					  	  step=Repositories
					  else
						  step=Locale
					  fi
					  ;;
		Repositories) whereAmI="${whereAmI/Repositories/\\Z1Repositories\\Z3}"
					  if repositories="$(GetRepositories)" 
					  then 
					  	  step=RootPassword
					  else
						  step=Keymap
					  fi
					  ;;
		RootPassword) whereAmI="${whereAmI/Root_Password/\\Z1Root_Password\\Z3}"
					  if rootPassword="$(GetRootPassword)" 
					  then 
						  step=Users
					  else
						  step=Repositories
					  fi
					  ;;
			   Users) whereAmI="${whereAmI/Users/\\Z1Users\\Z3}"
					  if usersList="$(GetUsers)"
			   		  then
						  step=Summary
					  else
						  step=RootPassword
					  fi
					  ;;
			 Summary) whereAmI='Start_Again<-\Z1Summary\Z3->Create_Answer_File'
					  if GetSummary
				 	  then
						  break
					  else
						  hostname='' timezone='' locale='' language=''
						  keymap='' repositories='' rootPassword='' usersList=''
						  step=Hostname
					  fi
					  ;;
		esac
	done
}
CollectingDataFromMenu
