#!/usr/bin/env bash

#
# query AD for a given user's account details.
#

#ldapsearch -h nwd2dc1.ad.analog.com -x -Drmaracle@ad.analog.com -W -b dc=ad,dc=analog,dc=com samaccountname=fszorc


#### The Old Simple Script:
#QUESTION=$1
#CMD="ldapsearch -h nwd2dc1.ad.analog.com -x -D${USER}@ad.analog.com -W -b dc=ad,dc=analog,dc=com samaccountname=${QUESTION}"
#${CMD}
####


# Setup debugging
debugging=1 # 1=debug on, 0=debug off

debugit()
    { # Output debug messages if the debugging flag is set.
      # Prints any/all arguments to stdout if debugging is on.
    if [ ${debugging} == 1 ]
        then echo -e "DEBUG: $@"
    fi
    }


disp_help()
    { # Print script help to screen, and exit.
      # Optional argument will set exit value.
        echo
        echo "This utility must be run by a non-root user."
        echo "usage: $0 {OPTION}"
        echo
        if [ $# = 1 ]
            then
                if [[ $1 =~ '^[0-9]+$' ]]
                    then exit $1
                    else exit 2
                fi
            else
                exit
        fi
    }


main()
    { # The main function
    local run_this
    run_this="$@"
    debugit "Running Command:\n\t${run_this}"
    ${run_this}
    }


# Interactive Mode Values:
INT_AD_SERVER=("nwd2dc1.ad.analog.com" "nwd2dc2.ad.analog.com" "adsjdc1.ad.analog.com" "Other...")
INT_AD_CREDS=("${USER}" "Other...")
INT_BASE_DN=("dc=ad,dc=analog,dc=com" "Other...")
INT_FILTER=("samaccountname" "mail" "manager" "name" "memberOf" "displayName" "extensionAttribute7" "extensionAttribute8" "sn" "cn" "dn")

# Default Values:
AD_SERVER="nwd2dc1.ad.analog.com"
AD_CREDS="svc_adsys@ad.analog.com"
AD_CREDS_PW="!2345s"
BASE_DN="dc=ad,dc=analog,dc=com"
AD_FILTER="samaccountname"
AD_VALUE=""
interactive_mode=0


yay_nay()
    { # A yes/no prompt
    local yaynay
    if [ $# > 0 ]
        then
            MSG="$@"
        else
            MSG="Would you like to continue?"
    fi
    read -p "${MSG} [y/N]" yaynay
    yaynay=$(echo ${yaynay:0:1} | tr "[a-z]" "[A-Z]")
    case ${yaynay} in
        Y)
            return 0
        ;;
        N)
            return 1
        ;;
        "")
            return 1 # Default to No
            #return 0 # Default to Yes
        ;;
        *)
            yay_nay $@
            return $?
        ;;
    esac
    }


getOther()
    { # The user answered "Other..." to a question. Now they need to tell us what their actual answer is.

    Other=""
    if [ $# > 0 ]
        then
            MSG="$@"
        else
            MSG="Please provide \"Other\": "
    fi
    read -p "${MSG}: "  Other
    }

promptFor()
    { # A multiple choice prompt.
      # Required Areguments:
      #    1. A quoted prompt string that will be presented to the user.
      #    2. The name of the variable that holds all the values used for multiple choice.
        echo "Prompt for... not implemented"
    }

doMenu()
    { # Create a menu
      # Required Argument is an ARRAY.
      # The array must have as it's last item, the word "Quit" to allow 
    select item in $@ "Quit"
        do
            if [ "${REPLY}" -eq "$#" ]
                then
                 echo "Not implemented yet"
            fi
        done
    }

goInteractive()
    { # Prompt user for all the variables we need, because it's easier than remembering all that AD malarkey.
      # Required Arguments:
      #    1. The name(s) (in a space seperated list) of the global variable that holds an array of items to present to the user for selection.

    # Begin formulating a command with the parts we already know
    local cmd_part
    cmd_part="ldapsearch -W"
    #-h ${AD_SERVER} -x -D${AD_CREDS} -b${BASE_DN} ${ATTRIBUTE}=${AD_VALUE}"

    # Iterate over the arguments, and prompt user for the value of each.

    # for arg in $@
    #     do
    #         case $arg in
    #             INT_AD_SERVER)
    #             ;;
    #             INT_AD_CREDS)
    #             ;;
    #             INT_FILTER)
    #             ;;
    #             INT_BASE_DN)
    #             ;;
    #             *)
    #             ;;


    }


# Option Arguments
optspec="s:u:a:v:-:"
while getopts "${optspec}" opt
    do
        case "${opt}" in
            -)
                debugit "parsing long option: \"--${OPTARG%=*}\""
                case "${OPTARG}" in
                    server)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        AD_SERVER="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    server=*)
                        AD_SERVER=${OPTARG#*=}
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    user)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        AD_CREDS="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    user=*)
                        AD_CREDS=${OPTARG#*=}
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    attribute)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        AD_FILTER="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    attribute=*)
                        AD_FILTER=${OPTARG#*=}
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    value)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        AD_VALUE="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    value=*)
                        AD_VALUE="${OPTARG#*=}"
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    base)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        BASE_DN="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    base=*)
                        BASE_DN=${OPTARG#*=}
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    interactive)
                        debugit "...Long option \"--${OPTARG}\" called with value: \"${!OPTIND}\""
                        interactive_mode="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    interactive=*)
                        interactive_mode=${OPTARG#*=}
                        debugit "...Long option \"--${OPTARG%=*}\" called with value: \"${OPTARG#*=}\""
                    ;;
                    *)
                        if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                            echo "...Unknown option --${OPTARG}" >&2
                        fi
                    ;;
                esac
            ;;
            s)
                debugit "Short option \"-${opt}\" called."
                AD_SERVER=${OPTARG}
            ;;
            u)
                debugit "Short option \"-${opt}\" called."
                AD_CREDS=${OPTARG}
            ;;
            a)
                debugit "Short option \"-${opt}\" called."
                AD_FILTER=${OPTARG}
            ;;
            v)
                debugit "Short option \"-${opt}\" called."
                AD_VALUE="${OPTARG}"
            ;;
            i)
                debugit "Short option \"-${opt}\" called."
                interactive_mode=1
            ;;
            *)
                if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                    echo "Non-option argument: '-${OPTARG}'" >&2
                fi
            ;;
        esac
    done

# Escape $AD_VALUE so shell doesn't get in the way
#AD_VALUE="${AD_VALUE// /\\ }"

CMD="ldapsearch -h ${AD_SERVER} -x -D${AD_CREDS} -W -b${BASE_DN} ${AD_FILTER}='${AD_VALUE}'"
# debugit $CMD
# ldapsearch -h ${AD_SERVER} -x -D${AD_CREDS} -W -b${BASE_DN} ${AD_FILTER}="${AD_VALUE}"

if [ ${interactive_mode} -eq 1 ]
    then
        goInteractive
fi

CMD="ldapsearch -h ${AD_SERVER} -x -D${AD_CREDS} -W -b${BASE_DN} ${AD_FILTER}=${AD_VALUE}"
debugit $CMD
ldapsearch -h ${AD_SERVER} -x -D${AD_CREDS} -w${AD_CREDS_PW} -b${BASE_DN} ${AD_FILTER}="${AD_VALUE}"
