# Keylue (Key Clue): Alfred 2 Workflow for Menu Bar and Keyboard Maestro Hot Key Search


It is like [KeyCue][KeyCue] which helps you memorize or quickly launch hot keys. But it is still too much to pinpoint a shortcut from a 50+ entries with your eyeball. This workflow gives the freedom to search and filter the results and execute them from Alfred.




## Usage

Just one keywords `kc`: Show menu items and Keyboard Maestro hot keys. Hit `Enter` to execute.

The feedback results for each application are cached for speedy response. The cached results are reloaded if it is older than an hour.

To refresh staled feedback, append `!` after the keyword. For example, `kc ! query`.

![](https://raw.github.com/zhaocai/alfred2-keylue-workflow/master/screenshots/chrome.png)

## Installation

Two ways are provided:

1. You can download the [Keylue.alfredworkflow](https://github.com/zhaocai/alfred2-keylue-workflow/blob/master/Keylue.alfredworkflow?raw=true) and import to Alfred 2. This method is suitable for **regular users**.

2. You can `git clone` or `fork` this repository and use `rake install` and `rake uninstall` to install. Check `rake -T` for available tasks.
This method create a symlink to the alfred workflow directory: "~/Library/Application Support/Alfred 2/Alfred.alfredpreferences/workflows". This method is suitable for **developers**.

## Reference

- [Menu Search](http://www.alfredforum.com/topic/1993-menu-search/)
- [ctwise/menudump](https://github.com/ctwise/menudump)


## Copyright

Copyright (c) 2013 Zhao Cai <caizhaoff@gmail.com>

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option)
any later version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program. If not, see <http://www.gnu.org/licenses/>.




[KeyCue]: http://www.ergonis.com/products/keycue/
