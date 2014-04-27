RobotGhosts
===========

Spectral Robot Task Force

### How to Run Spectral

1. Install [dmd](http://dlang.org/download.html) and [dub](http://code.dlang.org/download)
2. Replace the version of dub you installed (probably in `C:\Program Files (x86)\dub`) with [Colden's custom version](https://www.dropbox.com/s/g4rjayw4pu7hnsg/dub.exe)
3. Clone this repo with SourceTree (see [here](https://answers.atlassian.com/questions/78279/how-do-i-clone-a-git-remote-repository) for more info)
4. Open the D2 Command Prompt (32 bit) from the start menu, and `cd` into the directory you cloned this repo into
5. Type `dub build --system` to build the game
  * If you get an error that dub is not a know command, follow [these instructions](https://github.com/Circular-Studios/Dash/wiki/Setting-Up-Your-Environment#setting-up-environment-variables--not-rit-igm-labs-)
6. From now on, you can run the game simply by typing `dub` into the D2 command prompt in the game directory
