DOMAINS=( "adsiv.analog.com." "csdesign.analog.com." "adsdesign.analog.com." "cld.analog.com." )
TYPES=( CFL VDI MGT DRAC ILO LOM CIMC CMC SP OTHER MGT MGMT)

digit()
    { #First argument is domain, second is machine type
    local myDomain
    local myType
    local myRegex
    local myGrepargs
    local myFilter
    local myAxfr
    myDomain=$1
    myType=$2

    myType=$(echo ${myType} | tr "[a-z]" "[A-Z]")

    case ${myType} in
        CFL)
            myRegex='.*cfl[0-9]+'
            myGrepargs='-E'
            myFilter='| grep -v "\-drac|\-ilo|\-lom|\-cimc|\-cmc|\-sp|\-mgt"'
        ;;
        VDI)
            myRegex='.*\-lx[0-9][0-9]'
            myGrepargs='-E'
            myFilter=''
        ;;
        MGT)
            myRegex='\-mgt'
            myGrepargs='-E'
            myFilter=''
        ;;
        DRAC)
            myRegex='\-drac'
            myGrepargs='-E'
            myFilter=''
        ;;
        ILO)
            myRegex='\-ilo'
            myGrepargs='-E'
            myFilter=''
        ;;
        LOM)
            myRegex='\-lom'
            myGrepargs='-E'
            myFilter=''
        ;;
        CIMC)
            myRegex='\-cimc'
            myGrepargs='-E'
            myFilter=''
        ;;
        CMC)
            myRegex='\-cmc'
            myGrepargs='-E'
            myFilter=''
        ;;
        SP)
            myRegex='\-sp'
            myGrepargs='-E'
            myFilter=''
        ;;
        MGMT)
            myRegex='\-drac|\-ilo|\-lom|\-cimc|\-cmc|\-sp|\-mgt'
            myGrepargs='-E'
            myFilter=''
        ;;
        OTHER)
            myRegex='.*cfl[0-9]+|.*\-lx[0-9][0-9]|\-drac|\-ilo|\-lom|\-cimc|\-cmc|\-sp|\-mgt'
            myGrepargs='-Ev'
            myFilter=''
        ;;
    esac

    
    echo "${ZONEXFR}" | grep -E ${myGrepargs} "${myRegex}" ${myFilter} | awk '{print $1}' > /tmp/${myDomain}-${myType}.hosts
    }

for domain in ${DOMAINS[@]}
    do
        ZONEXFR=$(dig axfr ${domain})
        for type in ${TYPES[@]}
            do
                digit ${domain} ${type}
            done
    done