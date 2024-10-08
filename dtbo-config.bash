#!/usr/bin/env bash
#
# Simple script for device tree overlay configure.
#
__copyright__='Copyright (C) 2022-2024 ikwzm'
__version__='0.5'
__license__='BSD-2-Clause'
__author__='ikwzm'
__author_email__='ichiro_k@ca2.so-net.ne.jp'
__url__='https://github.com/ikwzm/dtbo-utils'

set -e
set -o pipefail

script_name=$0
verbose=0
debug_level=0
need_dtb=0
need_name=0
dry_run=0

if [[ -z $CONFIG_DTBO_PATH ]]; then
    if   [[ -d "/config/device-tree/overlays/" ]]; then
	CONFIG_DTBO_PATH="/config/device-tree/overlays/"
    else
	CONFIG_DTBO_PATH="/sys/kernel/config/device-tree/overlays/"
    fi
fi

do_help()
{
    echo "NAME"
    echo "     $script_name - Device Tree Overlay Configure"
    echo ""
    echo "SYNOPSYS"
    echo "     $script_name [<options>] DT_OVERLAY_NAME"
    echo ""
    echo "DESCRIPTION"
    echo "     Device Tree Overlay Configure"
    echo "        Create : Create Device Tree Overlay Directory"
    echo "        Remove : Remove Device Tree Overlay Directory"
    echo "        Load   : Load to Device Tree Overlay Directory"
    echo "        Install: Create and Load"
    echo "        List   : Print List of Device Tree Overlay Directory"
    echo "        Status : Print Status of Device Tree Overlay Directory"
    echo ""
    echo "OPTIONS"
    echo "        -h, --help         Run Help    command"
    echo "        -c, --create       Run Create  command"
    echo "        -r, --remove       Run Remove  command"
    echo "        -l, --load         Run Load    command"
    echo "        -i, --install      Run Install command"
    echo "        -t, --list         Run List    command"
    echo "        -s, --status       Run Status  command"
    echo "        -v, --verbose      Turn on verbosity"
    echo "        -d, --debug        Turn on debug"
    echo "        -n, --dry-run      Don't actually run any command"
    echo "        --dts DTS          Specify Device Tree Overlay Source File"
    echo "        --dtb DTB          Specify Device Tree Overlay Blob File"
    echo ""
    echo "VARIABLES"
    echo "        DTS                Device Tree Overlay Source File"
    echo "        DTB                Device Tree Overlay Blob File"
    echo "        DT_OVERLAY_NAME    Device Tree Overlay Name"
    echo "        CONFIG_DTBO_PATH   Device Tree Overlay Configuration Path"
    echo "                           Default='$CONFIG_DTBO_PATH'"
}

check_config_dtbo_path()
{
    if [[   -z $CONFIG_DTBO_PATH ]]; then
	echo "$script_name: CONFIG_DTBO_PATH not specified"
	exit 1
    fi
    if [[ ! -d $CONFIG_DTBO_PATH ]]; then
	echo "$script_name: $CONFIG_DTBO_PATH sepcified in CONFIG_DTBO_PATH does not exist"
	exit 1
    fi
}

run_command()
{
    local command=$1
    if [[ $dry_run -ne 0 ]] || [[ $verbose -ne 0 ]]; then
	echo "$command"
    fi
    if [[ $dry_run -eq 0 ]]; then
        eval "$command"
    fi
}    

dtbo_create()
{
    check_config_dtbo_path
    run_command "mkdir $CONFIG_DTBO_PATH/$1"
}

dtbo_remove()
{
    check_config_dtbo_path
    run_command "rmdir $CONFIG_DTBO_PATH/$1"
}

dtbo_start()
{
    if [[ -f "$CONFIG_DTBO_PATH/$1/status" ]]; then
        dtbo_status=$(cat "$CONFIG_DTBO_PATH/$1/status" )
        if [[ $dtbo_status = "0" ]] || [[ $dtbo_status = "1" ]]; then
            run_command "echo 1 > $CONFIG_DTBO_PATH/$1/status"
        fi
    fi
}

dtbo_load_dts()
{
    check_config_dtbo_path
    run_command "cat $2 | dtc -@ -I dts -O dtb > $CONFIG_DTBO_PATH/$1/dtbo"
    dtbo_start $1
}

dtbo_load_dtb()
{
    check_config_dtbo_path
    run_command "cat $2 > $CONFIG_DTBO_PATH/$1/dtbo"
    dtbo_start $1
}

dtbo_list()
{
    check_config_dtbo_path
    run_command "ls -1 $CONFIG_DTBO_PATH"
}

dtbo_status()
{
    check_config_dtbo_path
    if [[ -z $1 ]]; then
      run_command "find $CONFIG_DTBO_PATH    -name status -printf '%h : %f = ' -exec cat {} \;"
    else
      run_command "find $CONFIG_DTBO_PATH/$1 -name status -printf '%h : %f = ' -exec cat {} \;"
    fi
}

do_load()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: load $1 $2 $3"
    fi
    if [[ $2 == "dts" ]]; then
	dtbo_load_dts $1 $3
    fi
    if [[ $2 == "dtb" ]]; then
	dtbo_load_dtb $1 $3
    fi
}

do_create()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: create $1"
    fi
    dtbo_create $1
}

do_remove()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: remove $1"
    fi
    dtbo_remove $1
}

do_install()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: install $1 $2 $3"
    fi
    dtbo_create $1
    if [[ $2 == "dts" ]]; then
	dtbo_load_dts $1 $3
    fi
    if [[ $2 == "dtb" ]]; then
	dtbo_load_dtb $1 $3
    fi
}

do_list()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: list"
    fi
    dtbo_list
}

do_status()
{
    if [[ $verbose -gt 0 ]] || [[ $debug_level -gt 0 ]]; then
	echo "## $script_name: status  $1"
    fi
    dtbo_status $1
}

while [ $# -gt 0 ]; do
    case "$1" in
	-v|--verbose)
	    verbose=1
	    shift
	    ;;
	-d|--debug)
	    debug_level=1
	    shift
	    ;;
	-n|--dry-run)
	    dry_run=1
	    shift
	    ;;
	-h|--help)
	    command_list+=("help")
	    shift
	    ;;
	-c|--create)
	    command_list+=("create")
	    need_name=1
	    shift
	    ;;
	-l|--load)
	    command_list+=("load")
	    need_name=1
	    need_dtb=1
	    shift
	    ;;
	-r|--remove)
	    command_list+=("remove")
	    need_name=1
	    shift
	    ;;
	-i|--install)
	    command_list+=("install")
	    need_name=1
	    need_dtb=1
	    shift
	    ;;
	-t|--list)
	    command_list+=("list")
	    shift
	    ;;
	-s|--status)
	    command_list+=("status")
	    shift
	    ;;
	--dts)
	    shift
	    DTS=$1
	    shift
	    ;;
	--dtb)
	    shift
	    DTB=$1
	    shift
	    ;;
	*)
	    DT_OVERLAY_NAME=$1
	    shift
	    ;;
    esac
done

if [[ $need_name -gt 0 ]] && [[ -z $DT_OVERLAY_NAME ]]; then
    if [[ -n $DTB ]]; then
	DT_OVERLAY_NAME=`basename $DTB .dtb`
    fi
    if [[ -n $DTS ]]; then
	DT_OVERLAY_NAME=`basename $DTS .dts`
    fi
    if [[ -z $DT_OVERLAY_NAME ]]; then
        echo "$script_name: Please specify DT_OVERLAY_NAME. see '$script_name --help'."
        exit 1
    fi
fi

if [[ $need_dtb -gt 0 ]]; then
    if [[   -z $DTS ]] && [[   -z $DTB ]]; then
        echo "$script_name: Please specify either DTS or DTB. see '$script_name --help'."
        exit 1
    fi
    if [[ ! -z $DTS ]] && [[ ! -z $DTB ]]; then
        echo "$script_name: Please specify only one of DTS or DTB. see '$script_name --help'."
        exit 1
    fi
    if [[ ! -z $DTS ]]; then
	format="dts"
	source_file=$DTS
    fi
    if [[ ! -z $DTB ]]; then
	format="dtb"
	source_file=$DTB
    fi
fi

if [[ "${#command_list[*]}" -eq 0 ]]; then
    command_list+=("help")
fi

for command in "${command_list[@]}"
do
    case "$command" in
	"help"   ) do_help ;;
	"install") do_install $DT_OVERLAY_NAME $format $source_file ;;
	"load"   ) do_load    $DT_OVERLAY_NAME $format $source_file ;;
	"create" ) do_create  $DT_OVERLAY_NAME ;;
	"remove" ) do_remove  $DT_OVERLAY_NAME ;;
	"list"   ) do_list ;;
	"status" ) do_status  $DT_OVERLAY_NAME ;;
    esac
done
