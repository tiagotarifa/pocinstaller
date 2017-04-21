# Peace of cake library for ArchLinux instalation
# Its just a start "lib"... There is a long hard work to do

ListRepositories() {
	local mirrorlist="/etc/pacman.d/mirrorlist"

	sed -r '
		1,6d
		1,$s/## /"/
		N
		s/$repo.*\n/" off/
		s/ Server = /" "/' "$mirrorlist" \
		| sort
}
