# Copyright (C) 2010 Edgar Gonzàlez i Pellicer <edgar.gip@gmail.com>
#
# This file is part of triqui-0.1.
#
# triqui is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 3 of the License, or (at your
# option) any later version.
#
# triqui is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with triqui; see the file COPYING.  If not, see
# <http://www.gnu.org/licenses/>.


# Loaded modules
declare -A triqui_loaded_modules
declare -A triqui_var_owner


# load <module>
function triqui_load () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Check the module is not loaded
    elif [[ ! -z ${triqui_loaded_modules[$1]} ]]; then
	# Count one more
	triqui_loaded_modules[$1]=$((${triqui_loaded_modules[$1]}+1))
	echo "Module $1 reference count increased"

    # Otherwise
    else
	# Process each directive
	while read drc; do
	    # Binary dir
	    if [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
		# Add to PATH
		export PATH="${PATH}:${BASH_REMATCH[1]}"
		echo "Added binary dir ${BASH_REMATCH[1]} to PATH"

	    # Include dir
	    elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
		# Add to CPPFLAGS
		export CPPFLAGS="${CPPFLAGS} -I${BASH_REMATCH[1]}"
		echo "Added include dir ${BASH_REMATCH[1]} to CPPFLAGS"

	    # Library dir
	    elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
		# Add to LDFLAGS
		export LDFLAGS="${LDFLAGS} -L${BASH_REMATCH[1]}"
		echo "Added library dir ${BASH_REMATCH[1]} to LDFLAGS"

		# Add to LD_LIBRARY_PATH
		export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BASH_REMATCH[1]}"
		echo "Added library dir ${BASH_REMATCH[1]} to LD_LIBRARY_PATH"

	    # Variable
	    elif [[ $drc =~ ^([A-Z_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		# Var and value
		local var=${BASH_REMATCH[1]}
		local value=${BASH_REMATCH[2]}

		# Ensure it is not owned by somebody else
		if [[ -z ${triqui_var_owner[$var]} ]]; then
		    # Set the variable
		    export $var=$value
		    echo "Set variable $var to $value"

		    # Own it
		    triqui_var_owner[$var]=$1

		else
		    # Warn
		    echo "Value for variable $var ignored: already owned by ${triqui_var_owner[$var]}"
		fi

	    # Other
	    elif [[ ! ( $drc =~ ^[[:space:]]*$ || $drc =~ ^# ) ]]; then
		# Warn
		echo "Ignored directive $drc"
	    fi
	done < ~/.triqui/$1.tri

	# Add it
	triqui_loaded_modules[$1]=1

	# Success
	echo "Module $1 loaded"
    fi
}


# loaded
function triqui_loaded () {
    # Modules
    local loaded=

    # Does the ~/.triqui directory exist?
    if [[ -d ~/.triqui ]]; then
	# List the .tri files
	local modules=`cd ~/.triqui; ls | perl -ne 'print "\$\` " if /.tri\$/'`;
	if [[ ! -z $modules ]]; then
	    for m in $modules; do
		if [[ ! -z ${triqui_loaded_modules[$m]} ]]; then
		    loaded="${loaded} $m(${triqui_loaded_modules[$m]})"
		fi
	    done
	fi
    fi

    # Any module found?
    if [[ -z $loaded ]]; then
	# No modules available
	loaded='<none>';
    fi

    # Print
    echo "Loaded modules: $loaded"
}


# ls
function triqui_ls () {
    # Modules
    local modules=

    # Does the ~/.triqui directory exist?
    if [[ -d ~/.triqui ]]; then
	# List the .tri files
	modules=`cd ~/.triqui; ls | perl -ne 'print "\$\` " if /.tri\$/'`;
    fi

    # Any module found?
    if [[ -z $modules ]]; then
	modules='<none>';
    fi

    # Print
    echo "Available modules: $modules"
}


# info <module>
function triqui_info () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Otherwise
    else
	# Is it loaded?
	if [[ -z ${triqui_loaded_modules[$1]} ]]; then
	    echo "Status: not loaded"
	else
	    echo "Status: loaded (${triqui_loaded_modules[$1]} referers)"
	fi

	# Process each directive
	while read drc; do
	    # Binary dir
	    if [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
		echo "Binary dir: ${BASH_REMATCH[1]}"

	    # Include dir
	    elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
		echo "Include dir: ${BASH_REMATCH[1]}"

	    # Lib dir
	    elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
		echo "Lib dir: ${BASH_REMATCH[1]}"
	
	    # Variable
	    elif [[ $drc =~ ^([A-Z_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		echo "Variable ${BASH_REMATCH[1]} = ${BASH_REMATCH[2]}"

	    # Other
	    elif [[ ! ( $drc =~ ^[[:space:]]*$ || $drc =~ ^# ) ]]; then
		# Warn
		echo "Ignored directive $drc"
	    fi
	done < ~/.triqui/$1.tri
    fi
}


# unload <module>
function triqui_unload () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Check if the modules is loaded
    elif [[ -z ${triqui_loaded_modules[$1]} ]]; then
	# Module is not loaded
	echo "Module $1 is not loaded"

    # Otherwise
    else
	# Count one less
	triqui_loaded_modules[$1]=$((${triqui_loaded_modules[$1]}-1))

	# Is it zero?
	if (( ${triqui_loaded_modules[$1]} == 0 )); then
	    # Unload!

	    # Process each directive
	    while read drc; do
	        # Binary dir
		if [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
		    local dir="${BASH_REMATCH[1]}"

		    # Remove from PATH
		    if [[ $PATH =~ ^(.*):$dir(.*)$ ]]; then
			export PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed binary dir $dir from PATH"

		    else
			echo "Binary dir $dir was not in PATH"
		    fi

	        # Include dir
		elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
		    local dir="${BASH_REMATCH[1]}"

		    # Remove from CPPFLAGS
		    if [[ $CPPFLAGS =~ ^(.*)[[:space:]]-I$dir(.*)$ ]]; then
			export CPPFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed include dir $dir from CPPFLAGS"

		    else
			echo "Include dir $dir was not in CPPFLAGS"
		    fi

	        # Lib dir
		elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
		    local dir="${BASH_REMATCH[1]}"

		    # Remove from LDFLAGS
		    if [[ $LDFLAGS =~ ^(.*)[[:space:]]-L$dir(.*)$ ]]; then
			export LDFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed lib dir $dir from LDFLAGS"

		    else
			echo "Lib dir $dir was not in LDFLAGS"
		    fi

		    # Remove from LD_LIBRARY_PATH
		    if [[ $LD_LIBRARY_PATH =~ ^(.*):$dir(.*)$ ]]; then
			export LD_LIBRARY_PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed lib dir $dir from LD_LIBRARY_PATH"
		    else
			echo "Lib dir $dir was not in LD_LIBRARY_PATH"
		    fi

	        # Variable
		elif [[ $drc =~ ^([A-Z_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		    local var=${BASH_REMATCH[1]}

		    # Ensure we are the owners
		    if [[ ${triqui_var_owner[$var]} = $1 ]]; then
			# Unset the variable
			export -n $var=
			echo "Unset variable $var"

			# Unown
			triqui_var_owner[$var]=

		    elif [[ -z ${triqui_var_owner[$var]} ]]; then
			# Warn
			echo "Value for variable $var ignored: owned by <unloaded-package>"

		    else
			# Warn
			echo "Value for variable $var ignored: owned by ${triqui_var_owner[$var]}"
		    fi

	        # Other
		elif [[ ! ( $drc =~ ^[[:space:]]*$ || $drc =~ ^# ) ]]; then
		    # Warn
		    echo "Ignored directive $drc"
		fi
	    done < ~/.triqui/$1.tri

	    # Delete the key
	    triqui_loaded_modules[$1]=

 	    # Success
	    echo "Module $1 unloaded"

	else
 	    # Success
	    echo "Module $1 reference count decreased"
	fi
    fi
}


# autoload
function triqui_autoload () {
    # Check if the file exists
    if [[ -e ~/.triqui/autoload ]]; then
	# Process each line
	while read line; do
            # Skip comments
       	    if [[ ! $line =~ ^# ]]; then
		# For each module
		for m in $line; do
		    # Load it, if it was not already loaded
		    if [[ -z ${triqui_loaded_modules[$m]} ]]; then
			triqui_load $m
		    fi
		done
	    fi
	done < ~/.triqui/autoload
    fi
}


# Front-end function
function triqui () {
    # Find the called function
    if [[ "$1" = info ]]; then
	# info <module>
	triqui_info $2

    elif [[ "$1" = load ]]; then
	# load <module>
	triqui_load $2

    elif [[ "$1" = loaded ]]; then
	# loaded
	triqui_loaded

    elif [[ "$1" = ls ]]; then
	# ls
	triqui_ls

    elif [[ "$1" = unload ]]; then
	# unload <module>
	triqui_unload $2

    else
	# error!
	echo "Usage: triqui [ <info|load|unload> <module> | loaded | ls ]"
    fi
}


# Autoload
triqui_autoload &> /dev/null
