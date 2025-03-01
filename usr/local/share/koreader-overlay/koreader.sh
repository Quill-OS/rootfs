#!/bin/sh
export LC_ALL="en_US.UTF-8"

# Compute our working directory in an extremely defensive manner
SCRIPT_DIR="$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)"
# NOTE: We need to remember the *actual* KOREADER_DIR, not the relocalized version in /tmp...
export KOREADER_DIR="${KOREADER_DIR:-${SCRIPT_DIR}}"

# We rely on starting from our working directory, and it needs to be set, sane and absolute.
cd "${KOREADER_DIR:-/dev/null}" || exit

# export dict directory
export STARDICT_DATA_DIR="data/dict"

# export external font directory
export EXT_FONT_DIR="/mnt/onboard/onboard/fonts"

# Prevent input device grabbing
export KO_DONT_GRAB_INPUT="true"

# check whether PLATFORM & PRODUCT have a value assigned by rcS
if [ -z "${PRODUCT}" ]; then
    # shellcheck disable=SC2046
    export $(grep -s -e '^PRODUCT=' "/proc/$(pidof -s udevd)/environ")
fi

if [ -z "${PRODUCT}" ]; then
    PRODUCT="$(/bin/kobo_config.sh 2>/dev/null)"
    export PRODUCT
fi

# PLATFORM is used in koreader for the path to the Wi-Fi drivers (as well as when restarting nickel)
if [ -z "${PLATFORM}" ]; then
    # shellcheck disable=SC2046
    export $(grep -s -e '^PLATFORM=' "/proc/$(pidof -s udevd)/environ")
fi

#if [ -z "${PLATFORM}" ]; then
#    PLATFORM="freescale"
#    if dd if="/dev/mmcblk0" bs=512 skip=1024 count=1 | grep -q "HW CONFIG"; then
#        CPU="$(ntx_hwconfig -s -p /dev/mmcblk0 CPU 2>/dev/null)"
#        PLATFORM="${CPU}-ntx"
#    fi
#
#    if [ "${PLATFORM}" != "freescale" ] && [ ! -e "/etc/u-boot/${PLATFORM}/u-boot.mmc" ]; then
#        PLATFORM="ntx508"
#    fi
#    export PLATFORM
#fi

# Make sure we have a sane-ish INTERFACE env var set...
if [ -z "${INTERFACE}" ]; then
    # That's what we used to hardcode anyway
    INTERFACE="eth0"
    export INTERFACE
fi

# We'll enforce UR in ko_do_fbdepth, so make sure further FBInk usage (USBMS)
# will also enforce UR... (Only actually meaningful on sunxi).
if [ "${PLATFORM}" = "b300-ntx" ]; then
    export FBINK_FORCE_ROTA=0
    # On sunxi, non-REAGL waveform modes suffer from weird merging quirks...
    FBINK_WFM="REAGL"
    # And we also cannot use batched updates for the crash screen, as buffers are private,
    # so each invocation essentially draws in a different buffer...
    FBINK_BATCH_FLAG=""
    # Same idea for backgroundless...
    FBINK_BGLESS_FLAG="-B GRAY9"
    # It also means we need explicit background padding in the OT codepath...
    FBINK_OT_PADDING=",padding=BOTH"

    # Make sure we poke the right input device
    KOBO_TS_INPUT="/dev/input/by-path/platform-0-0010-event"
else
    FBINK_WFM="GL16"
    FBINK_BATCH_FLAG="-b"
    FBINK_BGLESS_FLAG="-O"
    FBINK_OT_PADDING=""
    KOBO_TS_INPUT="/dev/input/event1"
fi

# We'll want to ensure Portrait rotation to allow us to use faster blitting codepaths @ 8bpp,
# so remember the current one before fbdepth does its thing.
IFS= read -r ORIG_FB_ROTA <"/sys/class/graphics/fb0/rotate"
echo "Original fb rotation is set @ ${ORIG_FB_ROTA}" >>crash.log 2>&1

# In the same vein, swap to 8bpp,
# because 16bpp is the worst idea in the history of time, as RGB565 is generally a PITA without hardware blitting,
# and 32bpp usually gains us nothing except a performance hit (we're not Qt5 with its QPainter constraints).
# The reduced size & complexity should hopefully make things snappier,
# (and hopefully prevent the JIT from going crazy on high-density screens...).
# NOTE: Even though both pickel & Nickel appear to restore their preferred fb setup, we'll have to do it ourselves,
#       as they fail to flip the grayscale flag properly. Plus, we get to play nice with every launch method that way.
#       So, remember the current bitdepth, so we can restore it on exit.
IFS= read -r ORIG_FB_BPP <"/sys/class/graphics/fb0/bits_per_pixel"
echo "Original fb bitdepth is set @ ${ORIG_FB_BPP}bpp" >>crash.log 2>&1
# Sanity check...
case "${ORIG_FB_BPP}" in
    8) ;;
    16) ;;
    32) ;;
    *)
        # Uh oh? Don't do anything...
        unset ORIG_FB_BPP
        ;;
esac

# The actual swap is done in a function, because we can disable it in the Developer settings, and we want to honor it on restart.
ko_do_fbdepth() {
    # On sunxi, the fb state is meaningless, and the minimal disp fb doesn't actually support 8bpp anyway...
    if [ "${PLATFORM}" = "b300-ntx" ]; then
        # NOTE: The fb state is *completely* meaningless on this platform.
        #       This is effectively a noop, we're just keeping it for logging purposes...
        echo "Making sure that rotation is set to Portrait" >>crash.log 2>&1
        ./fbdepth -R UR >>crash.log 2>&1
        # We haven't actually done anything, so don't do anything on exit either ;).
        unset ORIG_FB_BPP

        return
    fi

    # On color panels, we target 32bpp for, well, color, and sane addressing (it also happens to be their default) ;o).
    eval "$(./fbink -e | tr ';' '\n' | grep -e hasColorPanel | tr '\n' ';')"
    # shellcheck disable=SC2154
    if [ "${hasColorPanel}" = "1" ]; then
        # If color rendering has been disabled by the user, switch to 8bpp to completely skip CFA processing
        if grep -q '\["color_rendering"\] = false' 'settings.reader.lua' 2>/dev/null; then
            echo "Switching fb bitdepth to 8bpp (to disable CFA) & rotation to Portrait" >>crash.log 2>&1
            ./fbdepth -d 8 -R UR >>crash.log 2>&1
        else
            echo "Switching fb bitdepth to 32bpp & rotation to Portrait" >>crash.log 2>&1
            ./fbdepth -d 32 -R UR >>crash.log 2>&1
        fi

        return
    fi

    # Check if the swap has been disabled...
    if grep -q '\["dev_startup_no_fbdepth"\] = true' 'settings.reader.lua' 2>/dev/null; then
        # Swap back to the original bitdepth (in case this was a restart)
        if [ -n "${ORIG_FB_BPP}" ]; then
            # Unless we're a Forma/Libra, don't even bother to swap rotation if the fb is @ 16bpp, because RGB565 is terrible anyways,
            # so there's no faster codepath to achieve, and running in Portrait @ 16bpp might actually be broken on some setups...
            if [ "${ORIG_FB_BPP}" -eq "16" ] && [ "${PRODUCT}" != "frost" ] && [ "${PRODUCT}" != "storm" ]; then
                echo "Making sure we're using the original fb bitdepth @ ${ORIG_FB_BPP}bpp & rotation @ ${ORIG_FB_ROTA}" >>crash.log 2>&1
                ./fbdepth -d "${ORIG_FB_BPP}" -r "${ORIG_FB_ROTA}" >>crash.log 2>&1
            else
                echo "Making sure we're using the original fb bitdepth @ ${ORIG_FB_BPP}bpp, and that rotation is set to Portrait" >>crash.log 2>&1
                ./fbdepth -d "${ORIG_FB_BPP}" -R UR >>crash.log 2>&1
            fi
        fi
    else
        # Swap to 8bpp if things looke sane
        if [ -n "${ORIG_FB_BPP}" ]; then
            echo "Switching fb bitdepth to 8bpp & rotation to Portrait" >>crash.log 2>&1
            ./fbdepth -d 8 -R UR >>crash.log 2>&1
        fi
    fi
}

# we keep at most 500KB worth of crash log
if [ -e crash.log ]; then
    tail -c 500000 crash.log >crash.log.new
    mv -f crash.log.new crash.log
fi

CRASH_COUNT=0
CRASH_TS=0
CRASH_PREV_TS=0
# List of supported special return codes
KO_RC_RESTART=85
KO_RC_USBMS=86
KO_RC_HALT=88
# Because we *want* an initial fbdepth pass ;).
RETURN_VALUE=${KO_RC_RESTART}
while [ ${RETURN_VALUE} -ne 0 ]; do
    if [ ${RETURN_VALUE} -eq ${KO_RC_RESTART} ]; then
        ko_do_fbdepth
    fi

    ./reader.lua "$@" >>crash.log 2>&1
    RETURN_VALUE=$?

    # Did we crash?
    if [ ${RETURN_VALUE} -ne 0 ] && [ ${RETURN_VALUE} -ne ${KO_RC_RESTART} ] && [ ${RETURN_VALUE} -ne ${KO_RC_USBMS} ] && [ ${RETURN_VALUE} -ne ${KO_RC_HALT} ]; then
        # Increment the crash counter
        CRASH_COUNT=$((CRASH_COUNT + 1))
        CRASH_TS=$(date +'%s')
        # Reset it to a first crash if it's been a while since our last crash...
        if [ $((CRASH_TS - CRASH_PREV_TS)) -ge 20 ]; then
            CRASH_COUNT=1
        fi

        # Check if the user requested to always abort on crash
        if grep -q '\["dev_abort_on_crash"\] = true' 'settings.reader.lua' 2>/dev/null; then
            ALWAYS_ABORT="true"
            # In which case, make sure we pause on *every* crash
            CRASH_COUNT=1
        else
            ALWAYS_ABORT="false"
        fi

        # Show a fancy bomb on screen
        viewWidth=600
        viewHeight=800
        FONTH=16
        eval "$(./fbink -e | tr ';' '\n' | grep -e viewWidth -e viewHeight -e FONTH | tr '\n' ';')"
        # Compute margins & sizes relative to the screen's resolution, so we end up with a similar layout, no matter the device.
        # Height @ ~56.7%, w/ a margin worth 1.5 lines
        bombHeight=$((viewHeight / 2 + viewHeight / 15))
        bombMargin=$((FONTH + FONTH / 2))
        # Start with a big gray screen of death, and our friendly old school crash icon ;)
        # U+1F4A3, the hard way, because we can't use \u or \U escape sequences...
        # shellcheck disable=SC2039,SC3003,SC2086
        ./fbink -q ${FBINK_BATCH_FLAG} -c -B GRAY9 -m -t regular=./fonts/freefont/FreeSerif.ttf,px=${bombHeight},top=${bombMargin} -W ${FBINK_WFM} -- $'\xf0\x9f\x92\xa3'
        # With a little notice at the top of the screen, on a big gray screen of death ;).
        # shellcheck disable=SC2086
        ./fbink -q ${FBINK_BATCH_FLAG} ${FBINK_BGLESS_FLAG} -m -y 1 -W ${FBINK_WFM} -- "Don't Panic! (Crash n°${CRASH_COUNT} -> ${RETURN_VALUE})"
        if [ ${CRASH_COUNT} -eq 1 ]; then
            # Warn that we're waiting on a tap to continue...
            # shellcheck disable=SC2086
            ./fbink -q ${FBINK_BATCH_FLAG} ${FBINK_BGLESS_FLAG} -m -y 2 -W ${FBINK_WFM} -- "Tap the screen to continue."
        fi
        # And then print the tail end of the log on the bottom of the screen...
        crashLog="$(tail -n 25 crash.log | sed -e 's/\t/    /g')"
        # The idea for the margins being to leave enough room for an fbink -Z bar, small horizontal margins, and a font size based on what 6pt looked like @ 265dpi
        # shellcheck disable=SC2086
        ./fbink -q ${FBINK_BATCH_FLAG} ${FBINK_BGLESS_FLAG} -t regular=./fonts/droid/DroidSansMono.ttf,top=$((viewHeight / 2 + FONTH * 2 + FONTH / 2)),left=$((viewWidth / 60)),right=$((viewWidth / 60)),px=$((viewHeight / 64))${FBINK_OT_PADDING} -W ${FBINK_WFM} -- "${crashLog}"
        if [ "${PLATFORM}" != "b300-ntx" ]; then
            # So far, we hadn't triggered an actual screen refresh, do that now, to make sure everything is bundled in a single flashing refresh.
            ./fbink -q -f -s
        fi
        # Cue a lemming's faceplant sound effect!

        {
            echo "!!!!"
            echo "Uh oh, something went awry... (Crash n°${CRASH_COUNT}: $(date +'%x @ %X'))"
            echo "Running FW $(cut -f3 -d',' /mnt/onboard/.kobo/version) on Linux $(uname -r) ($(uname -v))"
        } >>crash.log 2>&1
        if [ ${CRASH_COUNT} -lt 5 ] && [ "${ALWAYS_ABORT}" = "false" ]; then
            echo "Attempting to restart KOReader . . ." >>crash.log 2>&1
            echo "!!!!" >>crash.log 2>&1
        fi

        # Pause a bit if it's the first crash in a while, so that it actually has a chance of getting noticed ;).
        if [ ${CRASH_COUNT} -eq 1 ]; then
            # NOTE: We don't actually care about what read read, we're just using it as a fancy sleep ;).
            #       i.e., we pause either until the 15s timeout, or until the user touches the screen.
            # shellcheck disable=SC2039,SC3045
            read -r -t 15 <"${KOBO_TS_INPUT}"
        fi
        # Cycle the last crash timestamp
        CRASH_PREV_TS=${CRASH_TS}

        # But if we've crashed more than 5 consecutive times, exit, because we wouldn't want to be stuck in a loop...
        # NOTE: No need to check for ALWAYS_ABORT, CRASH_COUNT will always be 1 when it's true ;).
        if [ ${CRASH_COUNT} -ge 5 ]; then
            echo "Too many consecutive crashes, aborting . . ." >>crash.log 2>&1
            echo "!!!! ! !!!!" >>crash.log 2>&1
            break
        fi

        # If the user requested to always abort on crash, do so.
        if [ "${ALWAYS_ABORT}" = "true" ]; then
            echo "Aborting . . ." >>crash.log 2>&1
            echo "!!!! ! !!!!" >>crash.log 2>&1
            break
        fi
    else
        # Reset the crash counter if that was a sane exit/restart
        CRASH_COUNT=0
    fi

    # Did we request a reboot/shutdown?
    if [ ${RETURN_VALUE} -eq ${KO_RC_HALT} ]; then
        break
    fi
done

# Wipe the clones on exit
rm -f "/tmp/koreader.sh"

echo "inkbox_splash" > /opt/ibxd
sleep 2.5
echo "gui_soft_start" > /opt/ibxd
