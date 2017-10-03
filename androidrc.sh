export PATH=$ANDROID_HOME/platform-tools:$PATH
export ANDROID_BUILD_AAPT=$ANDROID_HOME/build-tools/25.0.2/aapt
export PATH=${PATH}:${ANDROID_HOME}/tools
export PATH=${PATH}:${ANDROID_HOME}/platform-tools

# adbc starts device debugging via Wi-Fi 
function adbc {
    IP=`adb shell ifconfig wlan0 | grep 'inet addr:' | cut -d: -f2 | awk '{print $1}'`
    adb tcpip 5555
    adb connect $IP
    adb devices
}

# adbscr saves and opens a file (supports Ubuntu and macOS)
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


    echo "Shoot"
    adb shell screencap -p $DEVICE_PATH
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

# Wakes up the screen
function awake {
    IS_SCREEN_ON=`adb shell dumpsys power | grep 'mHoldingWakeLockSuspendBlocker' | awk '{print substr($1,32); }'`
    if [ "$IS_SCREEN_ON" = "false" ]; then
        echo "Unlocking" && adb shell input keyevent 82 && adb shell input keyevent 82 && adb shell input text 7265287527 && adb shell input keyevent 66
    else
        echo "Waking up" && adb shell input keyevent -1 && adb shell input keyevent -1
    fi
}

# Presses the lock button
function alock {
    adb shell input keyevent 26
}

# Gets package name and launcher activity of an apk file.
# This will work too if is launched from root dir of an Android project.
function adbpkg {
    if [ -n "$1" ]; then
        adbpkg2 $1
    else
        APK_FILES=`find app/build/outputs/apk/*.apk`
        COUNTER=0
        for FILE in $(echo $APK_FILES)
        do
            let COUNTER=COUNTER+1 
            echo "$COUNTER: $FILE"
        done

        if [ $COUNTER = 1 ]; then
            echo "Single file:"
            APK_PATH=$APK_FILES | sed -n "1p"
            adbpkg2 $APK_PATH
        else
            echo "Select a file:"
            read INPUT
            QUERY=$INPUT"p"
            echo $QUERY
            APK_PATH=`echo $APK_FILES | sed -n $QUERY`
            adbpkg2 $APK_PATH
        fi
    fi
}

# adbpkgapk ./path_to.apk
# Sould consider using adbpkg
function adbpkg2 {
    echo $1
    AAPT_DUMP=`$ANDROID_BUILD_AAPT dump badging $1`
    PACKAGE=`echo $AAPT_DUMP | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    ACTIVITY=`echo $AAPT_DUMP | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    echo $PACKAGE
    echo $ACTIVITY
}

function astart {
    package=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    activity=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    if [ -n "$1" ]; then
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    activity=`$ANDROID_BUILD_AAPT dump badging $1 | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    fi
    echo "adb shell am start -n $package/$activity --activity-clear-task"
    adb shell am start -n $package/$activity --activity-clear-task
}

function akill {
    package=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    activity=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    if [ -n "$1" ]; then
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    activity=`$ANDROID_BUILD_AAPT dump badging $1 | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    fi
    pid=`adb shell ps | grep $package | awk '{print $2}'`
    adb shell run-as $package kill $pid
}

function adbrealm {
    package=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    if [ -n "$1" ]; then
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    fi
    db_path="/data/data/$package/files/default.realm"
    adb shell run-as $package cp $db_path /sdcard/
    adb pull /sdcard/default.realm .
}

alias adbd='adb devices'
alias adbrip='adb kill-server'

function adbclear {
    package=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    if [ -n "$1" ]; then
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    fi
    echo $package
    adb shell run-as $package pm clear $package
}

function adbremove {
    package=`$ANDROID_BUILD_AAPT dump badging app/build/outputs/apk/*-debug.apk | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    if [ -n "$1" ]; then
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    fi
    echo $package
    adb shell run-as $package pm clear $package
    adb uninstall $package
}

function adbinstall {
    adb install -r $1
    package=`$ANDROID_BUILD_AAPT dump badging $1 | grep package | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    activity=`$ANDROID_BUILD_AAPT dump badging $1 | grep launchable-activity: | awk '{print $2}' | sed s/name=//g | sed s/\'//g`
    adb shell am start -n $package/$activity --activity-clear-task
}