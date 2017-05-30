# Peace of cake library for ArchLinux instalation
# Its just a start "lib"... There is a long hard work to do
#--------/ Getting Functions /---------------------------------------------------
GettingRepositories() {
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
	local repositories="$(eval dialog		\
		--stdout 							\
		--separator '"! s!^#!!; \\!"'		\
		--checklist "Repositories..." 0 0 0 \
		$repoList)"
	echo "${repositories#*;}"'! s!^#!!; \\!'
}
GettingKeymap() {
	local dir="/usr/share/kbd/keymaps"
	local keymapList="$(	\
		find "$dir" 		\
		-type f 			\
		-iname "*.map.gz" 	\
		-printf '%P layout off ')"
	
	eval 'dialog \
		--stdout \
		--radiolist "Keyboard Layout" 0 0 0' $keymapList
}
GettingConsoleFont() {
	local dir="/usr/share/kbd/consolefonts/"
	local fontList="$(	\
		find "$dir" 	\
		-maxdepth 1		\
		-type f 		\
		-iname "*.gz" 	\
		-printf '%P font off ')"

	eval 'dialog	\
		--stdout	\
		--radiolist "Console Font" 0 0 0' $fontList
}
GettingLocale() {
	local localeFile="/etc/locale.gen"
	local localeList="$(sed -r '
		/^# /d
		s/^#//
		s/([[:alnum:]]) ([[:alnum:]])/\1_\2/g
		s/ //g
		/^$/d
		s/$/ locale off/' "$localeFile")"
	
	eval dialog				\
		--stdout 			\
		--separate-output	\
		--checklist "Locales..." 0 0 0 $localeList
}
GettingTimezone() {
	local dir="/usr/share/kbd/keymaps"
	local timezoneList="$(		\
		find "$dir" 			\
		-type f 				\
		-iname "*.map.gz" 		\
		-printf '%P layout off ')"
	eval dialog				\
		--stdout 			\
		--separate-output 	\
		--checklist "Timezone..." 0 0 0 $timezoneList
}
GettingHostname() {
	dialog			\
		--stdout	\
		--inputbox "Hostname" 0 0
}
GettingRootPassword() {
	dialog			\
		--insecure	\
		--stdout	\
		--passwordbox "Root Password" 0 0
}
#--------/ Setting Functions /---------------------------------------------------
SettingRepositories() { 
	local repositories="$( GettingRepositories )"
	local repoFile="/etc/pacman.d/mirrorlist"

	echo "sed '$repositories' $repoFile"
}
#--------/ Installation Functions /---------------------------------------------
SynchronizingClock() {
	echo "Setting date and time..."
	if ntpd -q 2>&1 > /dev/null
	then
		hwclock --systohc
	else
		:	#TODO: Exception treatment
	fi
}
GeneratingFstab() {
	local mountPoint="$TargetMount"
	local fstab="$mountPoint/etc/fstab"

	genfstab -U "$mountPoint" >> "$fstab" || exit 3
}
InstallingBaseSystem() {
	#packages names separate by space
	local packages="base"
	local target="$TargetMount"

	pacstrap "$target" "$packages" || exit 2
}
#--------/ Installation /---------------------------------------------
BeforeInstallationProcess() {
	#SynchronizingClock
	#SettingRepositories "$( GettingRepositories )"
	GettingData
}
InstallationProcess() {
	local repositories="$( GettingRepositories )"
	local keymap="$( GettingKeymap )"
	local consoleFont="$( GettingConsoleFont )"
	local locale="$( GettingLocale )"
	local timezone="$( GettingTimezone )"
	local hostname="$( GettingHostname )"
	local rootPassword="$( GettingRootPassword )"

	SettingRepositories 	"$repositories"
	InstallingBaseSystem
	SettingKeymap			"$keymap"
	SettingConsoleFont		"$consoleFont"
	SettingLocale			"$locale"
	SettingTimezone			"$timezone"
	SettingHostname			"$hostname"
	GeneratingFstab		
	SettingRootPassword 	"$rootPassword"
}
AfterInstallationProcess() {
	SettingBootLoader
}
#--------//----------------------------------------------------------------------
