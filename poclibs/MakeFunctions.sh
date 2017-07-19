#!/bin/bash
#--------/ Header /-------------------------------------------------------------
# MakeFunctions.sh: Functions to support all others functions and pocinstaller.sh
# Site            : https://github.com/tiagotarifa/pocinstaller
# Author          : Tiago Tarifa Munhoz
# License         : GPL3
#
#--------/ Description /--------------------------------------------------------
#   This script has functions to create others files. 
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
# Hartmut Buhrmester: Ho rewrite wsusoffline script for Linux. I was inspired 
#   by the way you did your log, and copy some code too.
# Cidinha (my wife): For her patience and love.
# 
#--------/ History /------------------------------------------------------------
# Legend: '-' for features and '+' for corrections
#  Version: 1.0 released in 2017-07-19
#-------------------------------------------------------------------------------
MakeFirstBootScript(){ #USE: /target/path/scripttomake.sh package01 package02 ...
	local scriptToMake="$1"
	local packages="$2"
	local scriptModel="$DirPoclibs/FirstBootModel.sh"
	local log="SystemInstallation 14:"

	(
	cp "$scriptModel" "$scriptToMake" || return
	sed -i '
/LogMaker()/ i \
readonly Step="'"$log"'"      \
readonly Packages="'"$packages"'"' "$scriptToMake"
	)
	if [ $? -eq 0 ]
	then
		chmod +x "$scriptToMake"
		LogMaker "MSG" "$logStep First boot script created"
	else
		LogMaker "ERR" "$logStep Impossible to create the first boot script."
	fi
}
MakeAnswerFile(){ #Create a answer file in /tmp with collected data
	local title="AnswerFile"
	local profileFile="$1"
	local answerFile="/tmp/modified_${profileFile##*/}"
	local text="Answer file '$answerFile' generated! You can use this file to
		make automatic mass installs or a new automatic one." 
	eval 'cat <<-_eof_ >"$answerFile"
	'"$(cat $profileFile)"'	
	_eof_'
	GuiMessageBox "$title" "$text" || return
	LogMaker "LOG" "AnswerFile: Answer file generated in '$answerFile'"
	echo "$answerFile"
}
MakePreScript(){ #Use: MakePreScript /path/scripttomake.sh /path/answerfile
	local script="$1"
	local answerFile="$2"
	local logStep="$logStep"

	if sed -n '
		/^<pre-script>/,/^<\/pre-script>/!d
		s@^<pre-script>@exec 2> '"${script%.*}.log"'\nset -x@
		s/^<\/pre-script>/set +x/ 
		w '"$script"'
		' $answerFile
	then
		LogMaker "MSG" "$logStep '$script' created!"
	else
		LogMaker "ERR" "$logStep Impossible to create '$script'!"
	fi
}
MakePosScript(){ #Use: MakePosScript /path/scripttomake.sh /path/answerfile
	local script="$1"
	local answerFile="$2"
	local logStep="$logStep"

	if sed -n '
		/^<pos-script>/,/^<\/pos-script>/!d
		s@^<pos-script>@exec 2> '"${script%.*}.log"'\nset -x@
		s/^<\/pos-script>/set +x/ 
		w '"$script"'
		' $answerFile
	then
		LogMaker "MSG" "$logStep '$script' created!"
	else
		LogMaker "ERR" "$logStep Impossible to create '$script'!"
	fi
}
MakePreInitialScript(){ #Use: MakePreInitialScript /target /path/answerfile
	local target="$1"
	local answerFile="$2"
	local script="/root/pre-initial.sh"
	local logStep="$logStep"

	if sed -n '
		/^<pre-initial>/,/^<\/pre-initial>/!d
		s@^<pre-initial>@exec 2> '"${script%.*}.log"'\nset -x@
		s/^<\/pre-initial>/set +x/ 
		w '"${target}${script}"'
		' $answerFile
	then
		chmod a+x "${target}${script}"
		LogMaker "MSG" "$logStep '${target}${script}' created!"
	else
		LogMaker "ERR" "$logStep Impossible to create '${target}${script}'!"
	fi
}
MakePosInitialScript(){ #Use: MakePosInitialScript /target /path/answerfile
	local target="$1"
	local answerFile="$2"
	local script="/root/pos-script.sh"
	local logStep="$logStep"

	if sed -n '
		/^<pos-initial>/,/^<\/pos-initial>/!d
		s@^<pos-initial>@exec 2> '"${script%.*}.log"'\nset -x@
		s/^<\/pos-initial>/set +x/ 
		w '"${target}${script}"'
		' $answerFile
	then
		chmod a+x "${target}${script}"
		LogMaker "MSG" "$logStep '${target}${script}' created!"
	else
		LogMaker "ERR" "$logStep Impossible to create '${target}${script}'!"
	fi
}
MakeMkinitcpio(){ #Use: MakeMkinitcpio "/target/system/"
	local target="$1"
	arch-chroot $target mkinitcpio -p linux \
		&& LogMaker "MSG" "$logStep RAM filesystem generated (mkinitcpio)" \
		|| LogMaker "ERR" "$logStep Impossible to generate RAM filesystem (mkinitcpio)"
}
