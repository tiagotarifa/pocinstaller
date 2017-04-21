#!/bin/bash

#Initial script to collect and understand necessities of this project

F_CollectingMachineInfo() {
	#Constants
	readonly MachineMemSize="$(awk '$1 == "MemTotal:" {print $2}' /proc/meminfo)"
	readonly MountedTargetRoot="$(df --output=target /mnt | grep '/mnt')"
	readonly MountedTargetBoot="$(df --output=target /mnt/boot | grep '/mnt/boot')"
	readonly SwapActive="$(grep -Eo '/dev/.{8}' /proc/swaps)"
}
F_MinimalMachineMemoryValidate() {
	local memorySize="$MachineMemSize"

	if [ "$memorySize" -lt 524288 ]
	then
		echo "Memory low: $memorySize"
	else
		echo "Memory ok: $memorySize"
	fi
}
F_IsRootMounted() {
	local targetRoot="$MountedTargetRoot"

	if [ "$targetRoot" == '/mnt' ]
	then
		echo "Root partition is mounted in /mnt."
	else
		echo "Have you mounted your root partition in '/mnt' ?"
	fi
}
F_IsBootMounted() {
	local targetBoot="$MountedTargetBoot"

	if [ "$targetBoot" == '/mnt/boot' ]
	then
		echo "Boot partition is mounted in /mnt/boot."
	else
		echo "Have you mounted your boot partition in '/mnt/boot' ?"
	fi
}
F_IsSwapActivated() {
	swap="$SwapActive"

	if [ -n "$swap" ]
	then
		echo "Swap is on in $swap"
	else
		echo "Have you activated you swap partition?"
	fi
}
F_PreInstall() {
	F_CollectingMachineInfo
	F_MinimalMachineMemoryValidate
	F_IsRootMounted
	F_IsBootMounted
	F_IsSwapActivated
}
F_PreInstall
