# Android Oh My Zsh Plugin

Various useful tools for developing Android apps.

## Prerequisites
* [ohmyz.sh](https://ohmyz.sh/)
* Android SDK
* [fzf is a general-purpose command-line fuzzy finder](https://github.com/junegunn/fzf)

## Installation

Pull plugin into the zsh plugins dir:


```zsh
git clone https://github.com/simonas-dev/android-ohmyzsh.git $ZSH_CUSTOM/plugins/android --depth=1
```

Into `.zshrc` file add:

```zsh
# Define `ANDROID_HOME`. E.g. for macOS
export ANDROID_HOME=${HOME}/Library/Android/sdk

plugins=(
    android
)
```

Reboot terminal or run `zsh` to restart the session.
