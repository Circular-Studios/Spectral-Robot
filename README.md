# Spectral Robot Task Force

![Spectral banner](https://cloud.githubusercontent.com/assets/512416/2869601/e68b30ca-d27b-11e3-8834-66cd12440707.png)

Spectral Robot Task Force is a turn-based strategy game similar to X-COM and Fire Emblem, with robot ghosts fighting supernatural criminals. It features a light-hearted plot that we want to couple with deep, rewarding gameplay. Online multiplayer will extend the fun past the singleplayer experience, and you can even play asynchronously if you want to take your time strategizing.

Created by [Circular Studios](http://circularstudios.com/).

## Features

* [Dash](https://github.com/Circular-Studios/Dash) engine, a publicly-developed engine written in D.
* Two factions, robots and supernatural criminals.
* Deathmatch game mode, extensible to further modes.
* Online multiplayer, currently just live (no asynchronous).

## Compiling

1. Install [dmd](http://dlang.org/download.html) and [dub](http://code.dlang.org/download). You can use [chocolatey](https://chocolatey.org/) if you are on Windows.
2. Clone this repository ([SourceTree](http://sourcetreeapp.com/) or command line [git](http://git-scm.com/) are good options).
3. Open a command prompt and `cd` into the directory containing Spectral.
4. Type `dub` to build and run the game.
  * If you get an error that dub is not a known command, follow [these instructions](https://github.com/Circular-Studios/Dash/wiki/Setting-Up-Your-Environment#setting-up-environment-variables--not-rit-igm-labs-)

## Packaging For Release

Install the [Dash CLI](https://github.com/Circular-Studios/Dash-CLI) and run `dash publish -o spectral.zip` in the top-level directory.

## License

Anything under the `Binaries`, `Config`, `Scripts`, and `UI` directories is under the MIT License. All other work is licensed under the [Creative Commons Attribution-NonCommercial 4.0 International License](http://creativecommons.org/licenses/by-nc/4.0/).
