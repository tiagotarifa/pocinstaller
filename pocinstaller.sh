#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# pocinstaller.sh: Manual or automatic installer for Archlinux (under development)
#
# Site		: https://github.com/tiagotarifa/pocinstaller
# Author	: Tiago Tarifa Munhoz
# License	: GPL3
#
#--------/ Description /--------------------------------------------------------
#     Piece of Cake installer aims to be a easy and fast installer for Arch 
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
#--------/ Constants /----------------------------------------------------------
readonly BackTitle="Piece of Cake Installer"
#Directories
readonly DirProfiles="profiles/"
readonly DirTarget="/mnt"
readonly DirBoot="$DirTarget/boot"
#Collecting environment information
readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
readonly MountedRootDir="$(df --output=target "$DirTarget" 2>/dev/null | grep "$DirTarget")"
readonly MountedBootDir="$(df --output=target "$DirBoot" 2>/dev/null | grep "$DirBoot")"
readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
readonly EfiFirmware='/sys/firmware/efi/efivars'
[ -s '/var/lib/pocinstaller/commonlib.sh' ] \
	&& readonly CommonlibFile='/var/lib/pocinstaller/commonlib.sh'
[ -s 'commonlib.sh' ] \
	&& readonly CommonlibFile='commonlib.sh'
[ -s '/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg' ] \
	&& readonly BaseAnswerFile='/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg'
[ -s 'profiles/Only_Base_Packages.cfg' ] \
	&& readonly BaseAnswerFile='profiles/Only_Base_Packages.cfg'
#--------/ Main Functions /-----------------------------------------------------
ValidatingPocInstaller(){
	local commonlib="$CommonlibFile"
	local baseAnswerFile="$BaseAnswerFile"
	if [ -n "$commonlib" ]
	then
		source "$commonlib"
	else
		cat <<-_eof_ 
		Error!
		   Library file 'commonlib.sh' is not found!
		   It should be in '$PWD/commonlib.sh'
		   or in '/var/lib/pocinstaller/commonlib.sh'!
		   POC Installer can't goes on!
		   Exiting...
		_eof_
		exit 1
	fi
	if [ -z "$baseAnswerFile" ]
	then
		cat <<-_eof_ 
		Error!
		   Profile file is no found!
		   It should be in '$PWD/profiles/Only_Base_Packages.cfg'
		   or in '/var/lib/pocinstaller/profiles/Only_Base_Packages.cfg'!
		   POC Installer can't goes on!
		   Exiting...
		_eof_
		exit 1
	fi
}
CollectingDataFromMenu(){
	local step=Hostname
	local -x hostname timezone locale keymap consoleFont consoleFontMap multilib
	local -x repositories rootPassword usersList usersPassword language whereAmI
	local -x profile
	while :
	do
		whereAmI="\Zr|Hostname|TZone|Locale|Lang|Keymap|Repo|RootPwd|Users|Multilib|Profile|\ZR"
		case $step in
			Hostname) whereAmI="${whereAmI/Hostname/\\Z1Hostname\\Z0}"
					  if hostname="$(GetHostname)"
					  then
					      step=Timezone
					  else
						  return 1
					  fi
					  ;;
		    Timezone) whereAmI="${whereAmI/TZone/\\Z1TZone\\Z0}"
					  if timezone="$(GetTimezone)"
					  then 
						  step=Locale
					  else
						  step=Hostname
					  fi
					  ;;
			  Locale) whereAmI="${whereAmI/Locale/\\Z1Locale\\Z0}"
					  if locale="$(GetLocale)"
				  	  then
					      step=Language
					  else
						  step=Timezone
					  fi
					  ;;
			Language) whereAmI="${whereAmI/Lang/\\Z1Lang\\Z0}"
					  if language="$(GetLanguage "$locale")"
				  	  then
					      step=Keymap
					  else
						  step=Locale
					  fi
					  ;;
		      Keymap) whereAmI="${whereAmI/Keymap/\\Z1Keymap\\Z0}"
					  if keymap="$(GetKeymap)"
				  	  then
					  	  step=Repositories
					  else
						  step=Locale
					  fi
					  ;;
		Repositories) whereAmI="${whereAmI/Repo/\\Z1Repo\\Z0}"
					  if repositories="$(GetRepositories)" 
					  then 
					  	  step=RootPassword
					  else
						  step=Keymap
					  fi
					  ;;
		RootPassword) whereAmI="${whereAmI/RootPwd/\\Z1RootPwd\\Z0}"
					  if rootPassword="$(GetRootPassword)" 
					  then 
						  step=Users
					  else
						  step=Repositories
					  fi
					  ;;
			   Users) whereAmI="${whereAmI/Users/\\Z1Users\\Z0}"
					  if usersList="$(GetUsers)"
			   		  then
						  usersPassword="$(grep -Eo '[[:alnum:]]{1,}:.+$'<<<"$usersList")"
						  usersList="$(sed 's/:.*//' <<<"$usersList")"
						  step=Multilib
					  else
						  step=RootPassword
					  fi
					  ;;
			Multilib) whereAmI="${whereAmI/Multilib/\\Z1Multilib\\Z0}"
					  if multilib="$(GetMultilib)" 
					  then 
						  step=Profile
					  else
						  step=Users
					  fi
					  ;;
			 Profile) whereAmI="${whereAmI/Profile/\\Z1Profile\\Z0}"
					  if profile="$(GetProfiles)" 
					  then 
						  step=Summary
					  else
						  step=Multilib
					  fi
					  ;;
			 Summary) whereAmI='|\ZrStartAgain<-\Z1Summary\Z0->CreateAnswerFile\ZR'
					  if GetSummary
				 	  then
						  #Fixing $locale changing '#' to ' '
						  locale="$( 
						  	sed '
								:a;N;$!ba
								s/#/ /g
								'<<<"$locale")"
						  break
					  else
						  hostname='' timezone='' locale='' language=''
						  keymap='' repositories='' rootPassword='' usersList=''
						  multilib='' usersPassword='' profile=''
						  step=Hostname
					  fi
					  ;;
		esac
	done
	MakeAnswerFile "$profile"
}
main() {
	ValidatingPocInstaller
	ValidatingEnvironment || exit 1
	SetNetworkConfiguration
	CollectingDataFromMenu
}
main
