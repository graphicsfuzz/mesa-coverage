#!/bin/bash

call_gcov() {
    # remove trailing slashes
    origwd=`pwd | sed -e 's+/*$++'`
    fullname=`readlink -f $1`
    gcno=`basename $fullname`
    wd=`dirname $fullname`
    err=`pwd`/_gcov_tmp_err
    while test "$origwd" != "$wd"
    do

        # echo "origwd: $origwd"
        # echo "wd:     $wd"
        # echo "gcno:   $gcno"

        (
            cd $wd
            gcov $gcno 2> $err 1> /dev/null
        )

        if < $err grep '^Cannot open ' > /dev/null
        then
            # up one directory
            up=`dirname $wd`
            prefix=`echo $wd | sed -e 's+'"$up/"'++'`
            gcno="$prefix/$gcno"
            wd=$up
        else
            echo "OK $1"
            break
        fi

    done
}
