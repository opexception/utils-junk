#!/bin/bash

# Checkin data to p4

repo_dir="/nobackup/rmaracle/p4-junk"
data_dir="/nobackup/rmaracle/junk"
count_file="/nobackup/rmaracle/p4-junk/counter"

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

mv ${data_dir}/${count} ${repo_dir}/

cd ${repo_dir}/${count}
p4 sync
p4 add ...
p4 submit -d "Submitting data chunk ${count}"

(( count++ ))

rm ${count_file}
echo ${count} > ${count_file}


