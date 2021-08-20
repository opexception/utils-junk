zip_file=$1
start_dir=$(pwd)

tempDir()
    { # Create a secure temp directory
    local TEMPDIR
    TEMPDIR=`mktemp`
    trap "rm -f ${TEMPDIR}" EXIT

    echo ${TEMPDIR}
    }

getSanList()
    { # Parse the cert file, and get the list of SANs
    san_list=( $(openssl x509 -in $1 -text | grep 'DNS:' | sed 's/DNS://g;s/,//g') )
    }


junk_dir=$(tempDir)

unzip -d ${junk_dir} ${zip_file}

junk_cert_dir=${zip_file%.zip}
junk_cert_file="${junk_cert_dir%_*}.crt"

cd ${junk_dir}


