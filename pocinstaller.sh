#!/bin/bash

#Initial script to collect and understand necessities of this project

CollectingMachineInfo() {
	#Constants
	readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
	readonly MountedTargetRoot="$(df --output=target /mnt | grep '/mnt')"
	readonly MountedTargetBoot="$(df --output=target /mnt/boot | grep '/mnt/boot')"
	readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
	readonly BootType="$(IsUEFIOrBios)"
}
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
	local targetRoot="$MountedTargetRoot"

	if [ "$targetRoot" == '/mnt' ]
	then
		echo "Root partition is mounted in /mnt."
	else
		echo "Have you mounted your root partition in '/mnt' ?"
	fi
}
IsBootMounted() {
	local targetBoot="$MountedTargetBoot"

	if [ "$targetBoot" == '/mnt/boot' ]
	then
		echo "Boot partition is mounted in /mnt/boot."
	else
		echo "Have you mounted your boot partition in '/mnt/boot' ?"
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
IsInternetAccessible() {
	local siteToTest="www.archlinux.org"

	if ping -c1 -q "$siteToTest" 2>&1 > /dev/null
	then
		return 0
	else
		return 1
	fi
}
PreInstall() {
	CollectingMachineInfo
	#MinimalMachineMemoryValidate
	#IsRootMounted
	#IsBootMounted
	#IsSwapActivated
	IsInternetAccessible && echo "Internet ok"
	SynchronizingClock
	Repositories="$(ChoosingRepositories)"
	Keymap="$(ChoosingKeymap)"
	ConsoleFont="$(ChoosingConsoleFont)"

	#TODO: Checks need to be done before start 
	#      from here (mount points, internet, etc.)
	InstallingBaseSystem
}
#------/arch.poclib/-----
ChoosingRepositories() {
	local file="/etc/pacman.d/mirrorlist"
	local repoList="$(sed -n '
		1,6d				#Remove header
		h					#keep current line on hold space (country)
		n					#load next line on pattern space (url)
		G					#attach hold space on parttern space (url \n country)
		s/\n/ /				#remove "new line" (url country)
		s/^Server = /"/		#remove garbage
		s/\$repo.*## /" "/
		s/$/" off/p
		' $file \
		| sort -k2)"		#Sort by country
	eval dialog 							\
		--stdout 							\
		--separate-output 					\
		--checklist "Repositories..." 0 0 0 \
		$repoList
}
ChoosingKeymap() {
	local dir="/usr/share/kbd/keymaps"
	local keymapList="$(		\
		find "$dir" 			\
		-type f 				\
		-iname "*.map.gz" 		\
		-printf '%P layout off ')"
	
	eval 'dialog \
		--stdout \
		--radiolist "Keyboard Layout" 0 0 0' $keymapList
}
ChoosingConsoleFont() {
	local dir="/usr/share/kbd/consolefonts/"
	local fontList="$(			\
		find "$dir" 			\
		-maxdepth 1				\
		-type f 				\
		-iname "*.gz" 			\
		-printf '%P font off ')"

	eval 'dialog \
		--stdout \
		--radiolist "Console Font" 0 0 0' $fontList
}
SynchronizingClock() {
	if ntpd -q 2>&1 /dev/null
	then
		hwclock -w
	else
		:	#TODO: Exception treatment
	fi
}
InstallingBaseSystem() {
	#packages names separate by space
	local packages="base"
	local target="/mnt"

	pacstrap "$target" "$packages" || exit 2
}
GeneratingFstab() {
	local mountPoint="/mnt"
	local fstab="/mnt/etc/fstab"

	genfstab -U "$mountPoint" >> "$fstab" || exit 3
}
#----------//------------
PreInstall
