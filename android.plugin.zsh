[[ $ANDROID_HOME == "" ]] && echo "android-ohmyzsh: ANDROID_HOME enviroment variable is missing!"

export PATH=$ANDROID_HOME/platform-tools:$PATH
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools

# Shorthand for adb devices
function adbd {
    adb devices
}

# Shorthand for adb kill-server
function adbrip {
    adb kill-server
}

function asn {
    adb get-serialno
}

# Start an emulator for a list of available ones.
function aemu {
    EMU=$($ANDROID_HOME/emulator/emulator -list-avds | fzf)
    echo "Starting $EMU"
    ($ANDROID_HOME/emulator/emulator -no-audio -no-skin -avd -no-snapshot-load $EMU &) &> /dev/null
}

# Writes text on device
# adbpaste - takes text from macOS clipboard and writes that.
# adbpaste "hello" – uses the provided arg as text.
function adbpaste {
    local DEVICE=""
  local TEXT=""
  
  # Parse arguments
  while [[ $# -gt 0 ]]; do
    case $1 in
      -s)
        DEVICE="$2"
        shift 2
        ;;
      *)
        TEXT="$1"
        shift
        ;;
    esac
  done

  if [ -z "$TEXT" ]; then
    TEXT=`pbpaste`
  fi

  if [ -z "$TEXT" ]; then
    echo "Clipboard empty!"
    exit 1
  fi

  TEXT=$(printf "%q" "$TEXT")
  
  if [ -n "$DEVICE" ]; then
    adb -s "$DEVICE" shell input text "$TEXT"
  else
    adb shell input text "$TEXT"
  fi
}

# Automatically starts debuging session if device is connetted on the same network.
function adbc {
    IP=`adb shell ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`
    adb tcpip 5555
    adb connect $IP
    adb devices
}

# Disable Andorid animations
function adbnoanim {
    adb shell settings put global window_animation_scale 0.0
    adb shell settings put global transition_animation_scale 0.0
    adb shell settings put global animator_duration_scale 0.0
}

# Enbled Andorid animations
function adbyesanim {
    adb shell settings put global window_animation_scale 1.0
    adb shell settings put global transition_animation_scale 1.0
    adb shell settings put global animator_duration_scale 1.0
}

# Replaces System UI with vanilla mocked state.
function adbdemo {
  CMD=$1
  echo $CMD
  if [ $CMD = "on" ]; then
      adb shell settings put global sysui_demo_allowed 1
      adb shell am broadcast -a com.android.systemui.demo -e command enter || exit
      adb shell am broadcast -a com.android.systemui.demo -e command clock -e hhmm 0800
      adb shell am broadcast -a com.android.systemui.demo -e command battery -e plugged false
      adb shell am broadcast -a com.android.systemui.demo -e command battery -e level 100
      adb shell am broadcast -a com.android.systemui.demo -e command network -e wifi show -e level 4
      adb shell am broadcast -a com.android.systemui.demo -e command network -e mobile show -e datatype none -e level 4
      adb shell am broadcast -a com.android.systemui.demo -e command notifications -e visible false
    elif [ $CMD = "off" ]; then
      adb shell am broadcast -a com.android.systemui.demo -e command exit
    else
        echo 'Mising argument of "on" or "off"'
    fi
}

# Fuzzy search for app by package name
function appfind {
    adb shell 'pm list packages -f' | sed -e 's/.*=//' | fzf
}

# Fuzzy search for app to dump package info by package name
function appinfo {
    for P in $(appfind)
    do
        echo "$P"
        adb shell dumpsys package $P
    done
}

# Fuzzy search for app to open on device by package name
function appopen {
    for P in $(appfind)
    do
        echo "$P"
        adb shell monkey -p $P -c android.intent.category.LAUNCHER 1
    done
}

# Fuzzy search for app to kill by package name
function appkill {
    for P in $(appfind)
    do
        PID=`adb shell ps | grep $P | awk '{print $2}'`
        EX="adb shell run-as $P kill $PID"
        echo $EX
        print -s $EX
        eval $EX
    done
}

# Fuzzy search for app to clear by package name
function appclear {
    for P in $(appfind)
    do
        EX="adb shell pm clear $P"
        echo $EX
        history -s $EX
        eval $EX
    done
}

# Fuzzy search for app to uninstall by package name
function appuninstall {
    for P in $(appfind)
    do
        EX="adb shell pm uninstall $P"
        echo $EX
        print -s $EX
        eval $EX
    done
}

# Takes a screenshot
# adbscr saves and opens a file (supports Linux and macOS)
# adbscr --save saves a file into currenct directory.
function adbscr {
    OPEN_FLAG=1
    FILE_NAME="screen.png"
    SAVE_DIR=/tmp/adbscr/

    if [ ! -d "$SAVE_DIR" ]; then
        mkdir $SAVE_DIR
    fi
    
    SAVE_PATH=$SAVE_DIR$FILE_NAME
    if [[ $* == *--save* ]]; then
        OPEN_FLAG=0
        FILE_NAME=`date +%Y_%m_%d-%H_%M_%s`".png"
        SAVE_PATH="./"$FILE_NAME
        echo "Saving to: "$SAVE_PATH
    fi

    DEVICE_PATH="/sdcard/"$FILE_NAME

    adbdemo on
    echo "Shoot"
    adb shell screencap -p $DEVICE_PATH
    adbdemo off
    echo "Pull"
    adb pull $DEVICE_PATH $SAVE_PATH
    if [[ $OPEN_FLAG == 1 ]]; then
        echo "Open "$SAVE_PATH
        if [[ "$OSTYPE" == "linux-gnu" ]]; then
            xdg-open $SAVE_PATH   
        elif [[ "$OSTYPE" == "darwin"* ]]; then
            open $SAVE_PATH
        else
            echo "Unsupported OS"
        fi
    fi
    adb shell rm $DEVICE_PATH
}
