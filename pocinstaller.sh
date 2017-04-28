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
# Linux. It's allow you to install by filling questions or using a .xml like
# an argument.(xml is the first idea. If its hard I'll change it)
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
#--------//---------------------------------------------------------------------

#--------/ Constants /----------------------------------------------------------
readonly TargetMount="/mnt"
readonly BootDir="$TargetMount/boot"
#CollectingMachineInfo
readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
readonly MountedRootDir="$(df --output=target "$TargetMount" | grep "$TargetMount")"
readonly MountedBootDir="$(df --output=target "$TargetMount/boot" | grep "$TargetMount/boot")"
readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
readonly BootType="$(IsUEFIOrBios)"
#--------//---------------------------------------------------------------------

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

#--------/ Installation Process /------------------------------------------------
RunAllCheckingFunctions
BeforeInstallationProcess
InstallationProcess
AfterInstallationProcess
#--------//----------------------------------------------------------------------

#------/arch.poclib/-----
#--------/ Setting Functions /---------------------------------------------
SettingRepositories() {
	local file="/etc/pacman.d/mirrorlist"
	local repoList="$(sed -n '
		1,6d				#Remove header
		h					#keep current line on hold space (country)
		n					#load next line on pattern space (url)
		G					#attach hold space on parttern space (url \n country)
		s/\n/ /				#remove "new line" (url country)
		s/^Server = /"/		#remove garbage and add double quotes ("url country)
		s/\$repo.*## /" "/	#separate by double quotes ("url" "country)
		s/$/" off/p			#("url" "country) --> ("url" "country" off)
		' $file \
		| sort -k2)"		#Sort by country
	local definedRepoList="$(eval dialog	\
		--stdout 							\
		--checklist "Repositories..." 0 0 0 \
		$repoList)"
	echo "definedRepoList -> $definedRepoList"
	exit
}
SettingKeymap() {
	local dir="$TargetMount/usr/share/kbd/keymaps"
	local keymapList="$(		\
		find "$dir" 			\
		-type f 				\
		-iname "*.map.gz" 		\
		-printf '%P layout off ')"
	
	local definedKeymap="$(eval 'dialog \
		--stdout 						\
		--radiolist "Keyboard Layout" 0 0 0' $keymapList)"
	echo "definedKeymap -> $definedKeymap"
	exit
	#TODO: Set keymap in vconsole.conf
}
SettingConsoleFont() {
	local dir="$TargetMount/usr/share/kbd/consolefonts/"
	local fontList="$(	\
		find "$dir" 	\
		-maxdepth 1		\
		-type f 		\
		-iname "*.gz" 	\
		-printf '%P font off ')"

	local definedFont="$(eval 'dialog	\
		--stdout 						\
		--radiolist "Console Font" 0 0 0' $fontList)"
	echo "definedFont -> $definedFont"
	exit
	#TODO: Set font on vconsole.conf
}
SettingLocale() {
	local localeFile="$TargetMount/etc/locale.gen"
	local localeList="$(sed -r '
		/^# /d
		s/^#//
		s/([[:alnum:]]) ([[:alnum:]])/\1_\2/g
		s/ //g
		/^$/d
		s/$/ locale off/' "$localeFile")"
	
	local definedLocaleList="$(eval dialog	\
		--stdout 							\
		--separate-output 					\
		--checklist "Repositories..." 0 0 0 \
		$localeList)"
	echo "definedLocaleList -> $definedLocaleList"
	exit
	#TODO: run locale-gen
	#TODO: set LANG= in /etc/locale.conf
}
SettingTimezone() {
	local dir="$TargetMount/usr/share/kbd/keymaps"
	local timezoneList="$(		\
		find "$dir" 			\
		-type f 				\
		-iname "*.map.gz" 		\
		-printf '%P layout off ')"
	local definedTimezone="$(eval dialog	\
		--stdout 							\
		--separate-output 					\
		--checklist "Timezone..." 0 0 0 \
		$timezoneList)"
	#TODO: Create symbolic link
	echo "definedTimezone-> $definedTimezone"
	exit
}
SettingHostname() {
	local hostnameFile="$TargetMount/etc/hostname"
	local hostname="$(dialog	\
		--stdout				\
		--inputbox "Hostname" 0 0)"
	echo "$hostname" > "$hostnameFile"
	#TODO: set hostname in /etc/hosts
}
SettingBootLoader() {
	echo ""
	#TODO: Choose between syslinux or grub and configure then
}
GeneratingFstab() {
	local mountPoint="$TargetMount"
	local fstab="$mountPoint/etc/fstab"

	genfstab -U "$mountPoint" >> "$fstab" || exit 3
}
SettingRootPassword() {
	local pwd="$(dialog			\
		--insecure				\
		--stdout				\
		--passwordbox "Root Password" 0 0)"

	#TODO: Set root password
	echo "root pwd -> $pwd"
	exit
}
SynchronizingClock() {
	echo "Setting date and time..."
	if ntpd -q 2>&1 > /dev/null
	then
		hwclock --systohc
	else
		:	#TODO: Exception treatment
	fi
}
#--------//----------------------------------------------------------------------

#--------/ Installation Functions /---------------------------------------------
InstallingBaseSystem() {
	#packages names separate by space
	local packages="base"
	local target="$TargetMount"

	pacstrap "$target" "$packages" || exit 2
}
#--------//----------------------------------------------------------------------

#--------/ Installation Functions /---------------------------------------------
BeforeInstallationProcess() {
	SettingRepositories
	SynchronizingClock
}
InstallationProcess() {
	InstallingBaseSystem
	SettingKeymap
	SettingConsoleFont
	SettingLocale
	SettingTimezone
	SettingHostname
	GeneratingFstab
	SettingRootPassword
}
AfterInstallationProcess() {
	SettingBootLoader
}
#--------//----------------------------------------------------------------------
#----------//------------
