#!/bin/bash

# Checkin data to p4

repo_dir="/nobackup/rmaracle/p4-junk"
data_dir="/nobackup/rmaracle/junk"
count_file="/nobackup/rmaracle/p4-junk/counter"
logfile="/home/rmaracle/p4-junk.log"

# Set ADI Modules
. /usr/cadtools/bin/modules.dir/module.sh
module load perforce


if [ -a ${count_file} ]
	then
		count=$(head -1 ${count_file})
	else
		touch ${count_file}
		count=0
fi

mv -v ${data_dir}/${count} ${repo_dir}/ >> ${logfile}

cd -v ${repo_dir}/${count} >> ${logfile}
p4 sync  >> ${logfile}
p4 add ...  >> ${logfile}
p4 submit -d "Submitting data chunk ${count}"  >> ${logfile}

(( count++ ))

rm ${count_file}
echo ${count} > ${count_file}

echo "##########################" >> ${logfile}
echo "## Finished" >> ${logfile}
echo "##########################" >> ${logfile}

