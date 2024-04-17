# Triqui

_Edgar Gonzàlez i Pellicer, 2010-2016_

`triqui` is a tool for `bash` which simplifies the management of environment
variables associated to software installed in non-standard locations (e.g.,
in user directories instead of system-wide ones).

It is based on the notion of modules, which can be individually loaded and
unloaded, as well as depend on others. Reference counting ensures
dependencies are loaded automatically and unloaded when it is safe to do so.

## Installation

1. Download the `triqui.bash` file and place it in the `~/.triqui` folder.

2. Append the following to the `~/.bash_profile`, `~/.bash_login` or
   `~/.bashrc` file, as needed.

   ```
   source ~/.triqui/triqui.bash
   ```

3. Add `.tri` files to the `~/.triqui` folder for each module.

## `.tri` Files

Each `.tri` file in the `~/.triqui` folder specifies one module.

Their format is line-based, with each line specifying one directive. Empty
lines, and those starting with a `#` sign are ignored. So do those that contain
an unknown directive, although after generating a warning.

The values of directives are subject to shell expansion.

### Directives

* `<name> = <value>`

  Exports the environment variable `<name>` with `<value>` as its expansion.
  Since values are subject to shell expansion, the `<name>` can be used (as
  `${NAME}`) in other directives.

* `ACLOCAL <path>`

  Appends `<path>` to the `ACLOCAL_PATH` variable, allowing `aclocal` to
  search for `.m4` files there.

* `ALIAS <name> = <value>`

  Adds `<name>` as an alias with `<value>` as its expansion.

* `BIN <path>`

  Appends `<path>` to the `PATH` variable, enabling it for program search.

* `-BIN <path>`

  Equivalent to `BIN`, but it prepends `<path>` to `PATH`.

* `INCLUDE <path>`

  Appends `-I<path>` to the `CPPFLAGS` variable, allowing `cpp` to search for
  `#include` files there.

* `INFO <path>`

  Appends `<path>` to the `INFOPATH` variable, allowing `info` to search for
  `.info` files there.

* `LIB <path>`

  Appends `-L<path>` to the `LDFLAGS` variable and `<path>` to the
  `LD_LIBRARY_PATH` one, respectively allowing `ld` to search for libraries
  there and those same libraries to be dynamically loaded when programs start.

* `-LIB <path>`

  Equivalent to `LIB`, but it prepends `<path>` to the variables.

* `MAN <path>`

  Appends `<path>` to the `MANPATH` variable, allowing `man` to search for
  pages there.

* `PERL5 <path>`

  Appends `<path>` to the `PERL5LIB` variable, allowing `perl` to search for
  `.pm` modules there.

* `PKG-CONFIG <path>`

  Appends `<path>` to the `PKG_CONFIG_PATH` variable, allowing `pkg-config` to
  search for `.pc` files there.

* `USE <module>`

  Expresses a dependency on another `<module>`.

## Commands

* `triqui ls`

  List all available modules in the `~/.triqui` folder.

* `triqui loaded`

  List all currently loaded modules.

* `triqui info <module>`

  Displays information about `<module>`. In particular, prints the different
  directives in a readable way.

  Note this is intended for human consumption. For automated processing, the
  raw `.tri` file is probably more convenient.

* `triqui load <module>`

  Loads `<module>`. This applies the changes to the different environment
  variables as determined by the directives in the `.tri` file.

  If the module depends on another one through a `USE` directive, the latter's
  reference count will be increased. If this was the first reference to the
  module, it will also be automatically loaded.

* `triqui unload <module>`

  Unload `<module>`. This undoes the changes to the variables that were done by
  `triqui load`.

  Note that this happens in a best-effort manner: the old values of the
  variables are not preserved when module loading happens, and instead they are
  reconstructed based on their current ones.

  If the module depends on another one though a `USE` directive, the latter's
  reference count will be decreased. If this was the last reference to the
  module, it will also be automatically unloaded.

* `triqui clear`

  Unload all currently loaded modules.

## The `autoload` file

  If the `~/.triqui/autoload` file exists, it is interpreted as containing one
  module name per line. These modules are automatically loaded when
  `triqui.bash` is sourced.
