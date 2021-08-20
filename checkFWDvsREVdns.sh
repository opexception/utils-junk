dig AXFR csdesign.analog.com. | grep -E '.*-lx[0-9]{2}' | grep -E "*.IN\sA.*" | awk '{print $1"\t\t"$5}' | while read -r line
    do
        parts=( $line )
        if rev="$(host ${parts[1]})"
            then
                hn=$(echo ${rev}|awk '{print $5}')
                if [ "${hn}" == "${parts[0]}" ]
                    then
                        echo "${parts[0]} is ${parts[1]} is ${hn}"
                    else
                        echo "FAILED: ${parts[0]} is ${parts[1]} but is not ${hn}"
                fi
            else
                echo "FAILED: ${parts[0]} is ${parts[1]}"
        fi
    done



#check seial of all slaves
srvs=(10.66.8.231 10.66.8.238 10.66.8.94 10.76.65.155 10.72.161.194 10.72.161.198 10.76.13.40 10.78.34.133 10.99.9.45 10.116.53.222 10.84.164.48 10.84.164.50 10.79.56.23 10.66.8.71 10.66.8.129 10.66.8.130 10.76.65.10 10.72.161.100 10.78.34.27 10.99.9.65 10.116.53.15 10.84.164.46)

for zone in csdesign.analog.com. {65,68,69}.76.10.in-addr.arpa.; do echo ${zone}; for srv in ${srvs[@]}; do echo -n "${srv}: "; dig @${srv} SOA +short ${zone}; done; done | awk '{print $1"\t"$4}' | grep -vE "1$"