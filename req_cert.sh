#!/bin/bash

clone_root_dir="/cad/local/certs/analog.com"
toc_file="TableOfContents.txt"

#gen_req_cmd=""

cert_dir="csr$(date +%Y%m%d)"

start_dir=$(pwd)

count=0


createDir()
    { # Create a new csr directory to store the CSR, and eventual cert files
    local CERTDIR
    if [ ${count} -ne 0 ]
        then # append the incrementor to the dir name
            CERTDIR="${cert_dir}.${count}"
        else
            CERTDIR=${cert_dir}
    fi

    if [ -d ${clone_root_dir}/${CERTDIR} ]
        then # We need to increment until we find an unused directory name
            (( count++ ))
            createDir
        else
            echo "New CSR will be in ${CERTDIR}"
            csr_path=${clone_root_dir}/${CERTDIR}
            mkdir -v ${csr_path}
            sleep 2
            return $?
    fi
    }


dumpEmail()
    { # Dump all needed info to send a cert request
    clear
    send_csr_to="matthew.morris@analog.com"
    email_subject="Duplicate *.analog.com cert"
    csr=$(cat "${csr_path}/star_analog_com.csr")
    body="Hi Matthew,\n\n\tI require another duplicate of the *.analog.com cert for an Apache webserver with the following SAN:\n\n<INSERT ALL NEEDED HOSTNAMES HERE>\n\n${csr}\n\nThanks!"

    echo -e "\n\n"
    echo -e "\tSend to: ${send_csr_to}"
    echo -e "\tSubject: ${email_subject}"
    echo -e "\n\tBody:\n\n--------------------------------------SNIP-------------------------------------\n"
    echo -e "${body}"
    echo -e "\n--------------------------------------SNIP-------------------------------------\n\n"
    }


addTocEntry()
    { # Add an entry to the TOC file
    local TOCFILE
    local CERTFILES
    local SANS
    local TOCENTRY
    TOCFILE=${clone_root_dir}/${toc_file}
    CERTFILES=( ${csr_path}/* )
    TOCENTRY="$(basename ${csr_path}):\n"
    for file in ${CERTFILES[@]}
        do
            file=$(basename ${file})
            case ${file} in
                "star_analog_com.csr")
                    TOCENTRY="${TOCENTRY}\t${file}: Certificate Request\n"
                ;;
                "star_analog_com.key")
                    TOCENTRY="${TOCENTRY}\t${file}: Private Key\n"
                ;;
                "DigiCertCA.crt")
                    TOCENTRY="${TOCENTRY}\t${file}: intermediate CA Cert\n"
                ;;
                "star_analog_com.crt")
                    TOCENTRY="${TOCENTRY}\t${file}: Host Cert\n"
                ;;
                "combo.pem")
                    TOCENTRY="${TOCENTRY}\t${file}: PEM Encoded Certificate Chain (intermediate and Host certs included)\n"
                ;;
                "bundle.crt")
                    TOCENTRY="${TOCENTRY}\t${file}: PEM Encoded Certificate Chain with Key (intermediate, Host, and Private Key included)\n"
                ;;
                "bundle.pfx")
                    TOCENTRY="${TOCENTRY}\t${file}: PFX Encoded Certificate Chain with Key (intermediate, Host, and Private Key included) for use with MS IIS server\n"
                ;;
                *)
                    TOCENTRY="${TOCENTRY}\t${file}: Unknown\n"
                ;;
            esac
        done
    TOCENTRY="${TOCENTRY}\tSAN:\n"
    # for san in SANS
    #     do
    #         TOCENTRY="${TOCENTRY}\t\t - ${san}\n"
    #     done
    TOCENTRY="${TOCENTRY}\n"
    #echo -e ${TOCENTRY} >> ${TOCFILE}
    echo -e ${TOCENTRY}
    }

if createDir
    then
        cd ${csr_path}
        echo -e "\n\n\n"
        openssl req -out star_analog_com.csr -subj '/C=US/ST=MA/L=Norwood/O=Analog Devices Inc./OU=Corporate_IT_Security/CN=*.analog.com' -new -newkey rsa:2048 -nodes -keyout star_analog_com.key
        dumpEmail
        addTocEntry
        cd ${start_dir}
    else
        echo "ERROR! Exiting"
        exit 1
fi

