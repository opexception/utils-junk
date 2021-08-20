#!/usr/bin/env bash


###############################################################################
## Initialize some variables
###############################################################################
HOSTNAME=$(uname -n)

# Remove the first ".", and everything after it from $HOSTNAME
SHORT_NAME=${HOSTNAME%%.*} 

 # Remove the first ".", and everything before it from $HOSTNAME
FULL_DOMAIN=${HOSTNAME#*.}

# Remove the first ".", and everything after it from $FULL_DOMAIN
DOMAIN=${FULL_DOMAIN%%.*} 

# Get a timestamp
tstamp=$(date +%Y%m%d%H%M%S)

# use the "-x" argument to set debugging.
# Initial debug level. Will be overwritten by "-x" argument, once it has been parsed.
#debug_level=0 # Silent. No additional debug output at all
#debug_level=1 # Write only ERRORs to stderr
#debug_level=2 # Write ERRORs to stderr, and WARNINGs to stdout
#debug_level=3 # Write ERRORs to stderr, WARNINGs and INFOs to stdout
debug_level=4 # Write ERRORs to stderr, WARNINGs, INFOs, and DEBUGs to stdout

debugit()
    { # Output debug messages depending on how $debug_level is set.
      # first argument is the type of message. Must be one of the following:
      #    ERROR
      #    WARNING
      #    INFO
      #    DEBUG
      # Example: 
      #   debugit INFO "This is how you use the debug feature."
      # Example output:
      #   INFO: This is how you use the debug feature.

    case ${debug_level} in
        0)
            return 0
        ;;
        1)
            case ${1} in
                ERROR)
                    shift
                    >&2 echo -e "ERROR: $@"
                    return 0
                ;;
                WARNING)
                    return 0
                ;;
                INFO)
                    return 0
                ;;
                DEBUG)
                    return 0
                ;;
                *)
                    >&2 echo -e "INTERNAL ERROR - Debug message type '$1' is invalid."
                    return 1
                ;;
            esac
        ;;
        2)
            case ${1} in
                ERROR)
                    shift
                    >&2 echo -e "ERROR: $@"
                    return 0
                ;;
                WARNING)
                    shift
                    echo -e "WARNING: $@"
                    return 0
                ;;
                INFO)
                    return 0
                ;;
                DEBUG)
                    return 0
                ;;
                *)
                    >&2 echo -e "INTERNAL ERROR - Debug message type '$1' is invalid."
                    exit 1
                ;;
            esac
        ;;
        3)
            case ${1} in
                ERROR)
                    shift
                    >&2 echo -e "ERROR: $@"
                    return 0
                ;;
                WARNING)
                    shift
                    echo -e "WARNING: $@"
                    return 0
                ;;
                INFO)
                    shift
                    echo -e "INFO: $@"
                    return 0
                ;;
                DEBUG)
                    return 0
                ;;
                *)
                    >&2 echo "INTERNAL ERROR - Debug message type '$1' is invalid."
                    return 1
                ;;
            esac
        ;;
        4)
            case ${1} in
                ERROR)
                    shift
                    >&2 echo -e "ERROR: $@"
                    return 0
                ;;
                WARNING)
                    shift
                    echo -e "WARNING: $@"
                    return 0
                ;;
                INFO)
                    shift
                    echo -e "INFO: $@"
                    return 0
                ;;
                DEBUG)
                    shift
                    echo -e "DEBUG: $@"
                    return 0
                ;;
                *)
                    >&2 echo "INTERNAL ERROR - Debug message type '$1' is invalid."
                    return 1
                ;;
            esac
        ;;
        *)
            echo "INTERNAL ERROR - Invalid debug level '${debug_level}'"
            echo "Setting debug level to default of 3"
            debug_level=3
        ;;
    esac
    }

disp_help()
    { # Print script help to screen, and exit.
      # Optional argument will set exit value.
        echo -e "usage: $0 {COMMAND} {OPTION} {ARGUMENTS}"
        echo -e "Commands:"
        echo -e "\tnew\t- Generate a CSR and PrivateKey for a new cert clone"
        echo -e "\tunpack\t- Unpack a returned zip file containg the matching certificate for an existing CSR"
        echo -e "Options:"
        echo -e "\t--dir\t- the directory root to operate within"
        echo -e "\t--recipient|-r\t- the email address of the recipient who will generate a cert clone from this CSR. Only valid when using the 'new' command."
        echo -e "\t--sender|-e\t- the reply-to email address that will be used when sending email. Only valid when using the 'new' command"
        echo -e "\t"
        echo -e "Argument:"
        echo -e "\tFor 'new' CSRs, this is an alternate directory to store generated files. Default is FQDN for request. For 'unpack', this is the filename of the zip file to unpack."
        if [ $# = 1 ]
            then
                if [[ "$1" =~ '^[0-9]+$' ]]
                    then exit $1
                    else exit 2
                fi
            else
                exit
        fi
    }


# Commands
if [ $# -ge 1 ]
    then
        debugit "Parsing command"
        if [ ${1#-} = $1 ]
            then
                commandArg="$1"
                shift
                debugit "Command specified is: ${commandArg}"

                case ${commandArg} in
                    yyyy)
                        debugit "Recognized command: ${commandArg}"
                    ;;
                    *)
                        debugit "Unknown command: ${commandArg}"
                        echo "${0}: Unknown command: ${commandArg}" >&2
                        disp_help 1
                esac
            else
                commandArg="NULL"
        fi
    else
        debugit "No command specified"
        disp_help
fi


# Options
optspec="hv:-:"
while getopts "${optspec}" opt
    do
        case "${opt}" in
            -)
                case "${OPTARG}" in
                    xxxx)
                        opt_xxxx="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    xxxx=*)
                        opt_xxxx=${OPTARG#*=}
                    ;;
                    verbose)
                        debug_level="${!OPTIND}"
                        (( OPTIND++ ))
                        debugit DEBUG "debug_level set to '${debug_level}'"
                    ;;
                    verbose=*)
                        debug_level=${OPTARG#*=}
                        debugit DEBUG "debug_level set to '${debug_level}'"
                    ;;
                    v|vv|vvv|vvvv)
                        case "${OPTARG}" in
                            v)
                                debug_level=1
                            ;;
                            vv)
                                debug_level=2
                            ;;
                            vvv)
                                debug_level=3
                            ;;
                            vvvv)
                                debug_level=4
                            ;;
                        esac
                        debugit DEBUG "debug_level set to '${debug_level}'"
                    ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "Unknown option --${OPTARG}" >&2
                        fi
                    ;;
                esac
            ;;
            v)
                case ${OPTARG} in
                    "0")
                        debug_level=0
                    ;;
                    "1")
                        debug_level=1
                    ;;
                    "2")
                        debug_level=2
                    ;;
                    "3")
                        debug_level=3
                    ;;
                    "4")
                        debug_level=4
                    ;;
                    v*)
                        case "${OPTARG}" in
                            v)
                                debug_level=2
                            ;;
                            vv)
                                debug_level=3
                            ;;
                            vvv)
                                debug_level=4
                            ;;
                            *)
                                >&2 echo "invalid debug level specified: 'v$(OPTARG)'"
                                disp_help 1
                            ;;
                        esac
                        debugit DEBUG "debug_level set to '${debug_level}'"
                    ;;
                    *)
                        >&2 echo "invalid debug level specified: '$(OPTARG)'"
                        disp_help 1
                    ;;
                esac
                debugit DEBUG "debug_level set to '${debug_level}'"
            ;;
            h)
                disp_help 0
            ;;
        esac
    done
shift $((OPTIND-1))

# Arguments
if [ $# -gt 0 ]
    then
        debugit "Parsing arguments"
        #Set argument variables here, like arg_file=$1
fi


#==============================================================================

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
            xit=$?
            sleep 2
            return ${xit}
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