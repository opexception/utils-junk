#!/bin/bash

# Checkin data to p4

repo_dir="/nobackup/rmaracle/p4-junk"
junk="/nobackup/rmaracle/junk"
count_file="/nobackup/rmaracle/p4-junk/counter"
logfile="/home/rmaracle/p4-junk.log"

[ -d ${repo_dir} ] || (echo "repo \"${repo_dir}\" doesn't exist"; exit 1)
[ -d ${junk} ] || (echo "data \"${junk}\" doesn't exist"; exit 1)

echo -e "--\n-- p4Checkin chunk Start: $(date +%Y%m%d-%H:%M:%S)\n--" | tee -a ${logfile}

# Set ADI Modules
. /usr/cadtools/bin/modules.dir/module.sh
module load perforce
module load python/adi/2.7.9


get_more_junk()
    { # Generate more junk
    local total_junk # $1
    local num_threads # $2
    local script_exe
    local db_path
    local junk_drawer
    local cmd
    total_junk=$1 # Number of GB of junk to generate for a 24hr checking period
    num_threads=$2 # Number of concurrent threads. we generate 1GB/thread
    script_exe="/home/rmaracle/dev/utils/data_profiler.py"
    db_path="/nobackup/rmaracle/advantage/wilmscan.db"
    junk_drawer="/nobackup/rmaracle/p4-junk"
    cmd="echo '${script_exe} -g -d ${db_path} -o ${junk_drawer} -q 1'; sleep 2"

    if [ ${total_junk} -gt ${num_threads} ]
        then
            remainder=$(expr ${total_junk} - ${num_threads})
        else
            remainder=0
            num_threads=${total_junk}
    fi

    for (( pass=1; pass<=${num_threads}; pass++))
        do 
            if [ ${pass} -eq ${num_threads} ]
                then 
                    ${cmd} # Don't background the last task, because we need towait for it to finish

                else 
                    ${cmd}& # Background this task so we can carry on with starting the the other threads
            fi
        done
    
    if [ ${remainder} -gt 0 ]
        then
            get_more_junk ${remainder} ${num_threads}
    fi

    }


if [ -a ${count_file} ]
	then
		count=$(head -1 ${count_file})
	else
		touch ${count_file}
		count=0
fi

if [ -d ${junk}/${count} ]
    then
        mv -v ${junk}/${count} ${repo_dir}/ | tee -a ${logfile}
    else
        echo "ERROR: ${junk}/$count} does not exist!"
        exit 1
fi

cd ${repo_dir}/${count} | tee -a ${logfile}
p4 sync  | tee -a ${logfile}
p4 add ...  | tee -a ${logfile}
p4 submit -d "Submitting data chunk ${count}"  | tee -a ${logfile}

#old_count=${count}
if [ ${count} -eq 23 ]
    then
        for (( c=0; c<24; c++ ))
            do
                rm -rv "${repo_dir}/${c}" | tee -a ${logfile}
            done
        count=0
        get_more_junk 20 2 | tee -a ${logfile} # 20GB, 2GB at a time
    else
        (( count++ ))
fi

rm ${count_file}
echo ${count} > ${count_file}



echo -e "##########################\n## Finished\n##########################" | tee -a ${logfile}


