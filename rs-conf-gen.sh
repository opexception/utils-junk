#!/usr/bin/env bash
#
# Generate an RS hosts config file.
#
# Can search DNS for cfl nodes, or provide hostlist
# PROTIP: Use this tool to search DNS, and output a host list, which can then be hand edited/checked, and fed back into this script.
#



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

# Default Output file name
def_outfile="rs-servers"

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
        echo "This is help."
        echo "usage: $0 {COMMAND} {OPTION} {ARGUMENTS}"
        if [ $# -eq 1 ]
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
# if [ $# -ge 1 ]
#     then
#         debugit DEBUG "Parsing command"
#         if [ ${1#-} = $1 ]
#             then
#                 commandArg="$1"
#                 shift
#                 debugit DEBUG "Command specified is: ${commandArg}"

#                 case ${commandArg} in
#                     yyyy)
#                         debugit DEBUG "Recognized command: ${commandArg}"
#                     ;;
#                     *)
#                         debugit ERROR "Unknown command: ${commandArg}"
#                         disp_help 1
#                 esac
#             else
#                 commandArg="NULL"
#         fi
#     else
#         debugit INFO "No command specified"
#         disp_help
# fi


# Options
optspec="hv:i:o:r:t:-:"
while getopts "${optspec}" opt
    do
        case "${opt}" in
            -)
                case "${OPTARG}" in
                    infile)
                        opt_infile="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    infile=*)
                        opt_infile=${OPTARG#*=}
                    ;;
                    outfile)
                        opt_outfile="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    outfile=*)
                        opt_outfile=${OPTARG#*=}
                    ;;
                    type)
                        opt_type="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    type=*)
                        opt_type=${OPTARG#*=}
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
                            debugit ERROR "Unknown option --${OPTARG}"
                        fi
                    ;;
                    rab-boxes)
                        opt_rabboxes="${!OPTIND}"
                        (( OPTIND++ ))
                    ;;
                    rab-boxes=*)
                        opt_rabboxes=${OPTARG#*=}
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
            i)
                opt_infile="${OPTARG}"
                debugit DEBUG "opt_infile = ${opt_infile}"
            ;;
            o)
                opt_outfile="${OPTARG}"
                debugit DEBUG "opt_outfile = ${opt_outfile}"
            ;;
            t)
                opt_type="${OPTARG}"
                debugit DEBUG "opt_type = ${opt_type}"
            ;;
            r)
                opt_rabboxes="${OPTARG}"
                debugit DEBUG "opt_rabboxes = ${opt_rabboxes}"
            ;;
        esac
    done
shift $((OPTIND-1))

# Arguments
# if [ $# -gt 0 ]
#     then
#         debugit DEBUG "Parsing arguments"
#         #Set argument variables here, like arg_file=$1
#         arg_outfile=$1
#         debugit DEBUG "arg_outfile = ${arg_outfile}"
# fi

###############################################################################
## SCRIPT
###############################################################################

if [ "${opt_type}xxx" == "xxx" ]
    then
        config_type="A"
    else
        config_type=$(echo ${opt_type:0:1} | tr "[a-z]" "[A-Z]")
fi

case config_type in
    S)
        def_outfile="rs-servers"
    ;;
    C)
        def_outfile="rs-clients"
    ;;
    A)
        def_outfile="rs-hosts"
    ;;
    *)
        debugit ERROR "invalid type specified: '${config_type}'"
        disp_help 1
    ;;
esac

if [ "${opt_outfile}xxx" == "xxx" ]
    then
        OUTFILE=${def_outfile}
    else
        OUTFILE=${opt_outfile}
fi

# Backup any existing outfile
if [ -a "${OUTFILE}" ]
    then
        mv ${OUTFILE}{,.${tstamp}}
        touch ${OUTFILE}
fi

debugit DEBUG "OUTFILE = ${OUTFILE}"



# Use opt_infile, or generate an infile from DNS dump
if [ "${opt_infile}xxx" == "xxx" ]
    then
        tmp_infile=$(mktemp)
        dig AXFR "${FULL_DOMAIN}." | grep -E "^cfl[0-9]{4}\.${FULL_DOMAIN}" > ${tmp_infile}
        INFILE=${tmp_infile}
    else
        INFILE=${opt_infile}
fi
debugit DEBUG "INFILE = ${INFILE}"

if [ "${opt_rabboxes}xxx" == "xxx" ]
    then
        RABBOXES="/dev/null"
    else
        RABBOXES=${opt_rabboxes}
fi
debugit DEBUG "RABBOXES = ${RABBOXES}"

while read line; do
    # try ssh to host and get num of cores
    # modification to lscpu to work with hyperthreading
    procs=`ssh -n ${line%%.*} -oBatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=2 'expr \`lscpu | egrep "Core" | cut -d":" -f2\` \* \`lscpu | egrep "Socket" | cut -d":" -f2\`'`

    # check connection successful
    if [[ ! -z "$procs" ]]
        then
            #echo $procs 
            # check if rab box
            debugit INFO "I think host ${line%%.*} has ${procs} processor cores (not counting hyperthreaded cores)"
            rsslots=$(( procs-2 ))
            debugit INFO "Will configure ${rsslots} slots for ${line%%.*}"
            rab=0
            # cat ${RABBOXES} | grep ${line%%.*}
            # if [ $? -eq 0 ]
            if $(grep -q ${line%%.*} ${RABBOXES})
                then
                    rab=1
                else
                    rab=0
            fi
            echo "HOST ${line%%.*} {" >> $OUTFILE
            echo "    OWNED=0;" >> $OUTFILE
            echo "    TOTAL_SLOTS=${rsslots};" >>$OUTFILE
            if [ $rab == 1 ]
                then
                    echo "    RAB=1;" >> $OUTFILE
            fi
            echo -e "}\n" >>$OUTFILE
    else
        debugit WARNING "Cannot connect to host '${line%%.*}'. skipped!"
  fi
done < $INFILE
