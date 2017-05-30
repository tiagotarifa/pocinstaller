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
#	#TODO: Function to backup files
#	#TODO: Function to set bootloader
#
#--------//---------------------------------------------------------------------

#--------/ Constants /----------------------------------------------------------
readonly TargetMount="/mnt"
readonly BootDir="$TargetMount/boot"
#CollectingMachineInfo
readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
readonly MountedRootDir="$(df --output=target "$TargetMount" | grep "$TargetMount")"
readonly MountedBootDir="$(df --output=target "$TargetMount/boot" | grep "$TargetMount/boot")"
readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
#--------//---------------------------------------------------------------------
source arch.poclib.sh
#--------/ Checking Functions /-------------------------------------------------
MinimalMachineMemoryValidate() {
	local memorySize="$MachineMemSize"

	if [ "$memorySize" -lt 524288 ]
	then
		echo "Memory low: $memorySize"
	else
		echo "Memory ok: $memorySize"
	fi
}
IsRootMounted() {
	local targetMount="$TargetMount"
	local mountedRootDir="$MountedRootDir"

	if [ "$mountedRootDir" == "$targetMount" ]
	then
		echo "Root partition is mounted in '$targetMount'."
	else
		echo "Have you mounted your root partition in '$targetMount' ?"
	fi
}
IsBootMounted() {
	local bootDir="$BootDir"
	local mountedBootDir="$MountedBootDir"

	if [ "$mountedBootDir" == "$bootDir" ]
	then
		echo "Boot partition is mounted in '$bootDir'."
	else
		echo "Have you mounted your boot partition in '$bootDir' ?"
	fi
}
IsSwapActivated() {
	local swap="$SwapActive"

	if [ -n "$swap" ]
	then
		echo "Swap is on in $swap"
	else
		echo "Have you activated you swap partition?"
	fi
}
IsUEFIOrBios() {
	local dir="/sys/firmware/efi/efivars"

	if [ -d "$dir" ]
	then
		echo "uefi"
	else
		echo "bios"
	fi

}
IsInternetAvaliable() {
	local siteToTest="www.archlinux.org"

	if ping -c1 -q "$siteToTest" 2>&1 > /dev/null
	then
		return 0
	else
		return 1
	fi
}
RunAllCheckingFunctions() {
	MinimalMachineMemoryValidate
	IsRootMounted
	IsBootMounted
	IsSwapActivated
	IsUEFIOrBios
	IsInternetAvaliable
}
#--------//----------------------------------------------------------------------
#--------/ Collecting Data /-----------------------------------------------------
GettingData() {
	local repositories="$( GettingRepositories )"
	local keymap="$( GettingKeymap )"
	local consoleFont="$( GettingConsoleFont )"
	local locale="$( GettingLocale )"
	local timezone="$( GettingTimezone )"
	local hostname="$( GettingHostname )"
	local rootPassword="$( GettingRootPassword )"

	readonly Repositories="$repositories"
	readonly Keymap="$keymap"
	readonly ConsoleFont="$consoleFont"
	readonly Locale="$locale"
	readonly Timezone="$timezone"
	readonly Hostname="$hostname"
	readonly RootPassword="$rootPassword"

	cat <<-_eof_
	Repositories: ${Repositories//\! s\!\^\#\!\!\; \\\!/ }
	Keymap: $Keymap
	ConsoleFont: $ConsoleFont
	Locale: $Locale
	Timezone: $Timezone
	Hostname: $Hostname
	Root password: $RootPassword
	_eof_
}

#--------/ Installation Process /------------------------------------------------
RunAllCheckingFunctions
read -s -n1 -p "Function RunAllCheckingFunctions performed!"; echo
GettingData
read -s -n1 -p "Function GettingData performed!"; echo
exit
InstallationProcess
read -s -n1 -p "Function InstallationProcess performed!"; echo
AfterInstallationProcess
read -s -n1 -p "Function AfterInstallationProcess performed!"; echo
#--------//----------------------------------------------------------------------
