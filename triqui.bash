# Active modules
declare -A triqui_active_modules

# load <module>
function triqui_load () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Check the module is not loaded
    elif [[ ! -z ${triqui_active_modules[$1]} ]]; then
	# Count one more
	triqui_active_modules[$1]=$((${triqui_active_modules[$1]}+1))
	echo "Module $1 reference count increased"

    # Otherwise
    else
	# Process each directive
	while read drc; do
	    # Binary dir
	    if [[ $drc =~ ^BIN[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		# Add to PATH
		export PATH="${PATH}:${BASH_REMATCH[1]}"
		echo "Added binary dir ${BASH_REMATCH[1]} to PATH"

	    # Include dir
	    elif [[ $drc =~ ^INCLUDE[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		# Add to CPPFLAGS
		export CPPFLAGS="${CPPFLAGS} -I${BASH_REMATCH[1]}"
		echo "Added include dir ${BASH_REMATCH[1]} to CPPFLAGS"

	    # Library dir
	    elif [[ $drc =~ ^LIB[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		# Add to LDFLAGS
		export LDFLAGS="${LDFLAGS} -L${BASH_REMATCH[1]}"
		echo "Added library dir ${BASH_REMATCH[1]} to LDFLAGS"

		# Add to LD_LIBRARY_PATH
		export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${BASH_REMATCH[1]}"
		echo "Added library dir ${BASH_REMATCH[1]} to LD_LIBRARY_PATH"

	    # Other
	    elif [[ ! $drc =~ ^[[:space:]]*$ ]]; then
		# Warn
		echo "Ignored directive $drc"
	    fi
	done < ~/.triqui/$1.tri

	# Add it
	triqui_active_modules[$1]=1

	# Success
	echo "Module $1 loaded"
    fi
}


# unload <module>
function triqui_unload () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Check if the modules is loaded
    elif [[ -z ${triqui_active_modules[$1]} ]]; then
	# Module is not loaded
	echo "Module $1 is not loaded"

    # Otherwise
    else
	# Count one less
	triqui_active_modules[$1]=$((${triqui_active_modules[$1]}-1))

	# Is it zero?
	if (( ${triqui_active_modules[$1]} == 0 )); then
	    # Unload!

	    # Process each directive
	    while read drc; do
	        # Binary dir
		if [[ $drc =~ ^BIN[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		    local dir="${BASH_REMATCH[1]}"

		    # Remove from PATH
		    if [[ $PATH =~ ^(.*):$dir(.*)$ ]]; then
			export PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed binary dir $dir from PATH"
		    else
			echo "Binary dir $dir was not in PATH"
		    fi

	        # Include dir
		elif [[ $drc =~ ^INCLUDE[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		    local dir="${BASH_REMATCH[1]}"

		    # Remove from CPPFLAGS
		    if [[ $CPPFLAGS =~ ^(.*)[[:space:]]-I$dir(.*)$ ]]; then
			export CPPFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
			echo "Removed include dir $dir from CPPFLAGS"
		    else
			echo "Include dir $dir was not in CPPFLAGS"
		    fi

	        # Lib dir
		elif [[ $drc =~ ^LIB[[:space:]]*=[[:space:]]*(.+)$ ]]; then
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
		    
	        # Other
		elif [[ ! $drc =~ ^[[:space:]]*$ ]]; then
		# Warn
		    echo "Ignored directive $drc"
		fi
	    done < ~/.triqui/$1.tri

	    # Delete the key
	    triqui_active_modules[$1]=

 	    # Success
	    echo "Module $1 unloaded"
	else
 	    # Success
	    echo "Module $1 reference count decreased"
	fi
    fi
}


# ls
function triqui_ls () {
    # Modules
    local modules=

    # Does the ~/.triqui directory exist?
    if [[ -d ~/.triqui ]]; then
	# List the .tri files
	modules=`cd ~/.triqui; ls | perl -ne 'print "\$\` " if /.tri\$/' | sort`;
	if [[ $modules = '' ]]; then
	    modules='<none>';
	fi
    else
	# No modules available
	modules='<none>';
    fi

    # Print
    echo "Available modules: $modules"
}


# print <module>
function triqui_print () {
    # Check the file exists
    if [[ ! -e ~/.triqui/$1.tri ]]; then
	# Module does not exist
	echo "Module $1 does not exist"

    # Otherwise
    else
	# Is it loaded?
	if [[ -z ${triqui_active_modules[$1]} ]]; then
	    echo "Status: not loaded"
	else
	    echo "Status: loaded (${triqui_active_modules[$1]} referers)"
	fi

	# Process each directive
	while read drc; do
	    # Binary dir
	    if [[ $drc =~ ^BIN[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		echo "Binary dir: ${BASH_REMATCH[1]}"

	    # Include dir
	    elif [[ $drc =~ ^INCLUDE[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		echo "Include dir: ${BASH_REMATCH[1]}"

	    # Lib dir
	    elif [[ $drc =~ ^LIB[[:space:]]*=[[:space:]]*(.+)$ ]]; then
		echo "Lib dir: ${BASH_REMATCH[1]}"
	
	    # Other
	    elif [[ ! $drc =~ ^[[:space:]]*$ ]]; then
		# Warn
		echo "Ignored directive $drc"
	    fi
	done < ~/.triqui/$1.tri
    fi
}


# Front-end function
function triqui () {
    # Find the called function
    if [[ "$1" = load ]]; then
	# load <module>
	triqui_load $2

    elif [[ "$1" = ls ]]; then
	# ls
	triqui_ls

    elif [[ "$1" = print ]]; then
	# print <module>
	triqui_print $2

    elif [[ "$1" = unload ]]; then
	# unload <module>
	triqui_unload $2

    else
	# error!
	echo "Usage: triqui [ [load|print|unload] <module> | ls ]"
    fi
}
