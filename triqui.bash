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
declare -A triqui_alias_owner
declare -A triqui_loaded_modules
declare -A triqui_var_owner


# Effective unload
function _triqui_effective_unload() {
    # Variables to be removed
    local -a removed_vars
    local -i n_removed_vars

    # Aliases to be removed
    local -a removed_aliases
    local -i n_removed_aliases

    # Modules to be unloaded
    local -a unloaded_mods
    local -i n_unloaded_mods

    # Process each directive
    while read drc; do
        # Using of other modules
        if [[ $drc =~ ^USE[[:space:]]+(.+)$ ]]; then
            local mods="${BASH_REMATCH[1]}"

            # Schedule for unload
            for m in $mods; do
                unloaded_mods[$n_unloaded_mods]=$m
                n_unloaded_mods=$n_unloaded_mods+1
            done

        # Aclocal dir
        elif [[ $drc =~ ^ACLOCAL[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from ACLOCAL_PATH
            if [[ $ACLOCAL_PATH =~ ^(.*):$dir(.*)$ ]]; then
                export ACLOCAL_PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed aclocal dir $dir from ACLOCAL_PATH"

            else
                echo "Aclocal $dir was not in ACLOCAL_PATH"
            fi

        # Alias
        elif [[ $drc =~ ^ALIAS[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+=[[:space:]]+(.+)$ ]]; then
            local name=${BASH_REMATCH[1]}

            # Ensure we are the owners
            if [[ ${triqui_alias_owner[$name]} = $1 ]]; then
                # Schedule for removal
                removed_aliases[$n_removed_aliases]=$name
                n_removed_aliases=$n_removed_aliases+1

            elif [[ -z ${triqui_alias_owner[$name]} ]]; then
                # Warn
                echo "Removal of alias $name skipped: owned by <unloaded-package>"

            else
                # Warn
                echo "Removal of alias $name skipped: owned by ${triqui_alias_owner[$alias]}"
            fi

        # Binary dir
        elif [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from PATH
            if [[ $PATH =~ ^(.*):$dir(.*)$ ]]; then
                export PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed binary dir $dir from PATH"

            else
                echo "Binary dir $dir was not in PATH"
            fi

        # Preemptive binary dir
        elif [[ $drc =~ ^-BIN[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from PATH
            if [[ $PATH =~ ^(.*)$dir:(.*)$ ]]; then
                export PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed preemptive binary dir $dir from PATH"

            else
                echo "Preemptive binary dir $dir was not in PATH"
            fi

        # Include dir
        elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from CPPFLAGS
            if [[ $CPPFLAGS =~ ^(.*)[[:space:]]-I$dir(.*)$ ]]; then
                export CPPFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed include dir $dir from CPPFLAGS"

            else
                echo "Include dir $dir was not in CPPFLAGS"
            fi

            # May clear it?
            if [[ -z $CPPFLAGS ]]; then
                unset CPPFLAGS
            fi

        # Lib dir
        elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from LDFLAGS
            if [[ $LDFLAGS =~ ^(.*)[[:space:]]-L$dir(.*)$ ]]; then
                export LDFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed lib dir $dir from LDFLAGS"

            else
                echo "Lib dir $dir was not in LDFLAGS"
            fi

            # May clear it?
            if [[ -z $LDFLAGS ]]; then
                unset LDFLAGS
            fi

            # Remove from LD_LIBRARY_PATH
            if [[ $LD_LIBRARY_PATH =~ ^(.*):$dir(.*)$ ]]; then
                export LD_LIBRARY_PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed lib dir $dir from LD_LIBRARY_PATH"
            else
                echo "Lib dir $dir was not in LD_LIBRARY_PATH"
            fi

            # May clear it?
            if [[ -z $LD_LIBRARY_PATH ]]; then
                unset LD_LIBRARY_PATH
            fi

        # Preemptive lib dir
        elif [[ $drc =~ ^-LIB[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from LDFLAGS
            if [[ $LDFLAGS =~ ^(.*)-L$dir[[:space:]](.*)$ ]]; then
                export LDFLAGS="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed preemptive lib dir $dir from LDFLAGS"

            else
                echo "Preemptive lib dir $dir was not in LDFLAGS"
            fi

            # May clear it?
            if [[ -z $LDFLAGS ]]; then
                unset LDFLAGS
            fi

            # Remove from LD_LIBRARY_PATH
            if [[ $LD_LIBRARY_PATH =~ ^(.*)$dir:(.*)$ ]]; then
                export LD_LIBRARY_PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed preemptive lib dir $dir from LD_LIBRARY_PATH"
            else
                echo "Preemptive lib dir $dir was not in LD_LIBRARY_PATH"
            fi

            # May clear it?
            if [[ -z $LD_LIBRARY_PATH ]]; then
                unset LD_LIBRARY_PATH
            fi

        # Man dir
        elif [[ $drc =~ ^MAN[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from MANPATH
            if [[ $MANPATH =~ ^(.*):$dir(.*)$ ]]; then
                export MANPATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed manpage dir $dir from MANPATH"

            else
                echo "Manpage dir $dir was not in MANPATH"
            fi

        # Info dir
        elif [[ $drc =~ ^INFO[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from INFOPATH
            if [[ $INFOPATH =~ ^(.*):$dir(.*)$ ]]; then
                export INFOPATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed info dir $dir from INFOPATH"

            else
                echo "Info dir $dir was not in INFOPATH"
            fi

        # Perl5 dir
        elif [[ $drc =~ ^PERL5[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from PERL5LIB
            if [[ $PERL5LIB =~ ^(.*):$dir(.*)$ ]]; then
                export PERL5LIB="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed perl5 dir $dir from PERL5LIB"

            else
                echo "Perl5 dir $dir was not in PERL5LIB"
            fi

        # Preemptive perl5 dir
        elif [[ $drc =~ ^-PERL5[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from PERL5LIB
            if [[ $PERL5LIB =~ ^(.*)$dir:(.*)$ ]]; then
                export PERL5LIB="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed perl5 dir $dir from PERL5LIB"

            else
                echo "Perl5 dir $dir was not in PERL5LIB"
            fi

        # Pkg-config dir
        elif [[ $drc =~ ^PKG-CONFIG[[:space:]]+(.+)$ ]]; then
            local dir=`eval echo "${BASH_REMATCH[1]}"`

            # Remove from PKG_CONFIG_PATH
            if [[ $PKG_CONFIG_PATH =~ ^(.*):$dir(.*)$ ]]; then
                export PKG_CONFIG_PATH="${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
                echo "Removed pkg-config dir $dir from PKG_CONFIG_PATH"

            else
                echo "pkg-config dir $dir was not in PKG_CONFIG_PATH"
            fi

        # Variable
        elif [[ $drc =~ ^([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
            local var=${BASH_REMATCH[1]}

            # Ensure we are the owners
            if [[ ${triqui_var_owner[$var]} = $1 ]]; then
                # Schedule for removal
                removed_vars[$n_removed_vars]=$var
                n_removed_vars=$n_removed_vars+1

            elif [[ -z ${triqui_var_owner[$var]} ]]; then
                # Warn
                echo "Removal of variable $var skipped: owned by <unloaded-package>"

            else
                # Warn
                echo "Removal of variable $var skipped: owned by ${triqui_var_owner[$var]}"
            fi

        # Other
        elif [[ ! ( $drc =~ ^[[:space:]]*$ || $drc =~ ^# ) ]]; then
            # Warn
            echo "Ignored directive $drc"
        fi
    done < ~/.triqui/$1.tri

    # Effectively unset and unown variables
    for var in ${removed_vars[*]}; do
        unset $var
        triqui_var_owner[$var]=
        echo "Removed variable $var"
    done

    # Effectively remove and unown aliases
    for name in ${removed_aliases[*]}; do
        unalias $name
        triqui_alias_owner[$name]=
        echo "Removed alias $name"
    done

    # Effectively unload modules
    for m in ${unloaded_mods[*]}; do
        triqui_unload $m;
    done

    # Clear the key
    triqui_loaded_modules[$1]=
}


# clear
function triqui_clear () {
    # Effectively unload every module
    for m in ${!triqui_loaded_modules[@]}; do
        # Is it still active?
        if [[ ! -z ${triqui_loaded_modules[$m]} ]]; then
            # Effectively unload
            _triqui_effective_unload $m

             # Success
            echo "Module $m unloaded"
        fi
    done

    # Success
    echo "All modules unloaded"
}


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
             # Using of other modules
            if [[ $drc =~ ^USE[[:space:]]+(.+)$ ]]; then
                local mods="${BASH_REMATCH[1]}"

                 # Load
                for m in $mods; do
                    triqui_load $m;
                done

            # Aclocal dir
            elif [[ $drc =~ ^ACLOCAL[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to ACLOCAL_PATH
                export ACLOCAL_PATH="${ACLOCAL_PATH}:$dir"
                echo "Added aclocal dir $dir to ACLOCAL_PATH"

            # Alias
            elif [[ $drc =~ ^ALIAS[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+=[[:space:]]+(.+)$ ]]; then
                local name=${BASH_REMATCH[1]}
                local value=`eval echo "${BASH_REMATCH[2]}"`

                # Ensure it is not owned by somebody else
                if [[ -z ${triqui_alias_owner[$name]} ]]; then
                    # Set the variable
                    alias $name="$value"
                    echo "Set alias $name to $value"

                    # Own it
                    triqui_alias_owner[$name]=$1

                else
                    # Warn
                    echo "Value for alias $name ignored: already owned by ${triqui_alias_owner[$name]}"
                fi

            # Binary dir
            elif [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to PATH
                export PATH="${PATH}:$dir"
                echo "Added binary dir $dir to PATH"

            # Preemptive binary dir
            elif [[ $drc =~ ^-BIN[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to PATH
                export PATH="$dir:${PATH}"
                echo "Added preemptive binary dir $dir to PATH"

            # Include dir
            elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to CPPFLAGS
                export CPPFLAGS="${CPPFLAGS} -I$dir"
                echo "Added include dir $dir to CPPFLAGS"

            # Library dir
            elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to LDFLAGS
                export LDFLAGS="${LDFLAGS} -L$dir"
                echo "Added library dir $dir to LDFLAGS"

                # Add to LD_LIBRARY_PATH
                export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:$dir"
                echo "Added library dir $dir to LD_LIBRARY_PATH"

            # Preemptive library dir
            elif [[ $drc =~ ^-LIB[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to LDFLAGS
                export LDFLAGS="-L$dir ${LDFLAGS}"
                echo "Added preemptive library dir $dir to LDFLAGS"

                # Add to LD_LIBRARY_PATH
                export LD_LIBRARY_PATH="$dir:${LD_LIBRARY_PATH}"
                echo "Added preemptive library dir $dir to LD_LIBRARY_PATH"

            # Man dir
            elif [[ $drc =~ ^MAN[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to MANPATH
                export MANPATH="${MANPATH}:$dir"
                echo "Added manpage dir $dir to MANPATH"

            # Info dir
            elif [[ $drc =~ ^INFO[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to INFOPATH
                export INFOPATH="${INFOPATH}:$dir"
                echo "Added info dir $dir to INFOPATH"

            # Perl5 dir
            elif [[ $drc =~ ^PERL5[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to PERL5LIB
                export PERL5LIB="${PERL5LIB}:$dir"
                echo "Added perl5 dir $dir to PERL5LIB"

            # Preemptive perl5 dir
            elif [[ $drc =~ ^-PERL5[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to PERL5LIB
                export PERL5LIB="$dir:${PERL5LIB}"
                echo "Added perl5 dir $dir to PERL5LIB"

            # Pkg-config dir
            elif [[ $drc =~ ^PKG-CONFIG[[:space:]]+(.+)$ ]]; then
                local dir=`eval echo "${BASH_REMATCH[1]}"`

                # Add to PKG_CONFIG_PATH
                export PKG_CONFIG_PATH="${PKG_CONFIG_PATH}:$dir"
                echo "Added pkg-config dir $dir to PKG_CONFIG_PATH"

            # Variable
            elif [[ $drc =~ ^([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                local var=${BASH_REMATCH[1]}
                local value=`eval echo ${BASH_REMATCH[2]}`

                # Ensure it is not owned by somebody else
                if [[ -z ${triqui_var_owner[$var]} ]]; then
                    # Set the variable
                    export $var="$value"
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

    # For every loaded module
    for m in ${!triqui_loaded_modules[@]}; do
        # Is it still active?
        if [[ ! -z ${triqui_loaded_modules[$m]} ]]; then
            # Add it
            loaded="${loaded} $m(${triqui_loaded_modules[$m]})"
        fi
    done

    # Any module found?
    if [[ -z $loaded ]]; then
        # No modules available
        loaded=' <none>';
    fi

    # Print
    echo "Loaded modules:$loaded"
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
            echo "Module $1: not loaded"
        else
            echo "Module $1: loaded (${triqui_loaded_modules[$1]} referers)"
        fi

        # Process each directive
        while read drc; do
            # Using of other modules
            if [[ $drc =~ ^USE[[:space:]]+(.+)$ ]]; then
                echo "Loaded modules: ${BASH_REMATCH[1]}"

            # Aclocal dir
            elif [[ $drc =~ ^ACLOCAL[[:space:]]+(.+)$ ]]; then
                echo "Aclocal dir: ${BASH_REMATCH[1]}"

            # Alias
            elif [[ $drc =~ ^ALIAS[[:space:]]+([A-Za-z0-9_]+)[[:space:]]+=[[:space:]]+(.+)$ ]]; then
                echo "Alias ${BASH_REMATCH[1]} = ${BASH_REMATCH[2]}"

            # Binary dir
            elif [[ $drc =~ ^BIN[[:space:]]+(.+)$ ]]; then
                echo "Binary dir: ${BASH_REMATCH[1]}"

            # Preemptive binary dir
            elif [[ $drc =~ ^-BIN[[:space:]]+(.+)$ ]]; then
                echo "Preemptive binary dir: ${BASH_REMATCH[1]}"

            # Include dir
            elif [[ $drc =~ ^INCLUDE[[:space:]]+(.+)$ ]]; then
                echo "Include dir: ${BASH_REMATCH[1]}"

            # Lib dir
            elif [[ $drc =~ ^LIB[[:space:]]+(.+)$ ]]; then
                echo "Lib dir: ${BASH_REMATCH[1]}"

            # Preemptive lib dir
            elif [[ $drc =~ ^-LIB[[:space:]]+(.+)$ ]]; then
                echo "Preemptive lib dir: ${BASH_REMATCH[1]}"

            # Man dir
            elif [[ $drc =~ ^MAN[[:space:]]+(.+)$ ]]; then
                echo "Manpage dir: ${BASH_REMATCH[1]}"

            # Info dir
            elif [[ $drc =~ ^INFO[[:space:]]+(.+)$ ]]; then
                echo "Info dir: ${BASH_REMATCH[1]}"

            # Perl5 dir
            elif [[ $drc =~ ^PERL5[[:space:]]+(.+)$ ]]; then
                echo "Perl5 dir: ${BASH_REMATCH[1]}"

            # Preemptive perl5 dir
            elif [[ $drc =~ ^-PERL5[[:space:]]+(.+)$ ]]; then
                echo "Preemptive perl5 dir: ${BASH_REMATCH[1]}"

            # Pkg-config dir
            elif [[ $drc =~ ^PKG-CONFIG[[:space:]]+(.+)$ ]]; then
                echo "Pkg-config dir: ${BASH_REMATCH[1]}"

            # Variable
            elif [[ $drc =~ ^([A-Za-z0-9_]+)[[:space:]]*=[[:space:]]*(.+)$ ]]; then
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
            _triqui_effective_unload $1

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
    local cmd=$1
    shift

    # Find the called function
    if [[ $cmd = clear ]]; then
        # clear
        triqui_clear

    elif [[ $cmd = info ]]; then
        # info <module>
        for m in $@; do
            triqui_info $m
        done

    elif [[ $cmd = load ]]; then
        # load <module>...
        for m in $@; do
            triqui_load $m
        done

    elif [[ $cmd = loaded ]]; then
        # loaded
        triqui_loaded

    elif [[ $cmd = ls ]]; then
        # ls
        triqui_ls

    elif [[ $cmd = unload ]]; then
        # unload <module>...
        for m in $@; do
            triqui_unload $m
        done

    else
        # error!
        echo "Usage: triqui <info|load|unload> <module> | clear | loaded | ls"
    fi
}


# Autoload
triqui_autoload &> /dev/null
