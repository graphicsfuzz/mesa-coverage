#!/bin/sh

datadir=$1

if test -z "$datadir"
then
    echo "Error: missing argument"
    echo "You must give as argument your GCOV_PREFIX directory (where *.gcda files are)"
    exit 1
fi

# clean
find ./mesa -type f -name '*.gcda' | xargs /bin/rm -f
find ./mesa -type f -name '*.gcov' | xargs /bin/rm -f

# remove trailing slashes
datadir=`echo $datadir | sed -e 's+/*$++'`

# get gcda files
rsync -avz --filter='+ */' --filter='+ *.gcda' --filter='- *' ${datadir}/mesa/ ./mesa/

./my_gcov.sh

# put aside gcov files
dest=`date "+%F_%H-%M-%S"`_gcov
mkdir $dest

rsync -avz --filter='+ */' --filter='+ *.gcov' --filter='- *' ./mesa/ $dest/

# lcov --directory . --capture --output-file coverage.info

# rm -rf html
# mkdir html
# genhtml --output-directory ./html/ coverage.info

# rsync -v coverage.info ${datadir}/
# rsync -avz html ${datadir}/
