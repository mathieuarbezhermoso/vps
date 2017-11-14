#!/bin/bash
#  ███╗   ██╗ ██████╗ ██████╗ ███████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ 
#  ████╗  ██║██╔═══██╗██╔══██╗██╔════╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
#  ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
#  ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
#  ██║ ╚████║╚██████╔╝██████╔╝███████╗██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
#  ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
#                                                              ╚╗ @marsmensch 2016-2017 ╔╝                   				
#                   
# version 	0.7.4-alpha GoByte
# date    	2017-11-13
#
# function:	part of the masternode scripts, source the proper config file
#                                                                      
# 	Instructions:
#               Run this script w/ the desired parameters. Leave blank or use -h for help.
#
#	Platforms: 	
#               - Linux Ubuntu 16.04 LTS ONLY on a Vultr VPS (its by far the cheapest option)
#               - Generic Ubuntu support will be added at a later point in time
#
#	System requirements:
#               - A vultr micro instance works for up to 5 masternodes 
#				- Activate the free IPv6 option for best results
#
# Twitter 	@marsmensch

# Useful variables
declare -r CRYPTOS=`ls -l config/ | egrep '^d' | awk '{print $9}' | xargs echo -n; echo`
declare -r DATE_STAMP="$(date +%y-%m-%d-%s)"
declare -r SCRIPTPATH=$( cd $(dirname ${BASH_SOURCE[0]}) > /dev/null; pwd -P )
declare -r MASTERPATH="$(dirname "${SCRIPTPATH}")"
declare -r SCRIPT_VERSION="v0.7.5"
declare -r SCRIPT_LOGFILE="/tmp/nodemaster_${DATE_STAMP}_out.log"
declare -r IPV4_DOC_LINK="https://www.vultr.com/docs/add-secondary-ipv4-address"

function showbanner() {
cat << "EOF"
 ███╗   ██╗ ██████╗ ██████╗ ███████╗███╗   ███╗ █████╗ ███████╗████████╗███████╗██████╗ 
 ████╗  ██║██╔═══██╗██╔══██╗██╔════╝████╗ ████║██╔══██╗██╔════╝╚══██╔══╝██╔════╝██╔══██╗
 ██╔██╗ ██║██║   ██║██║  ██║█████╗  ██╔████╔██║███████║███████╗   ██║   █████╗  ██████╔╝
 ██║╚██╗██║██║   ██║██║  ██║██╔══╝  ██║╚██╔╝██║██╔══██║╚════██║   ██║   ██╔══╝  ██╔══██╗
 ██║ ╚████║╚██████╔╝██████╔╝███████╗██║ ╚═╝ ██║██║  ██║███████║   ██║   ███████╗██║  ██║
 ╚═╝  ╚═══╝ ╚═════╝ ╚═════╝ ╚══════╝╚═╝     ╚═╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚══════╝╚═╝  ╚═╝
                                                             ╚╗ @marsmensch 2016-2017 ╔╝                   				
EOF
}

# To use this function:
# confirm && hg push ssh://..
# or
# confirm "Would you really like to do a push?" && hg push ssh://..
function get_confirmation() {
    # call with a prompt string or use a default
    read -r -p "${1:-Are you sure? [y/N]} " response
    case "$response" in
        [yY][eE][sS]|[yY]) 
            true
            ;;
        *)
            false
            ;;
    esac
}

# display the help message
function show_help(){
    clear
    showbanner
    echo "install.sh, version $SCRIPT_VERSION";
    echo "Usage example:";
    echo "install.sh (-p|--project) string [(-h|--help)] [(-n|--net) int] [(-c|--count) int] [(-r|--release) string] [(-w|--wipe)] [(-u|--update)]";
    echo "Options:";
    echo "-h or --help: Displays this information.";
    echo "-p or --project string: Project to be installed. REQUIRED.";
    echo "-n or --net: IP address type t be used (4 vs. 6).";
    echo "-c or --count: Number of masternodes to be installed.";
    echo "-r or --release: Release version to be installed.";
    echo "-w or --wipe: Wipe ALL local data for a node type. Combine with the -p option";
    echo "-u or --update: Update a specific masternode daemon. Combine with the -p option";
    exit 1;
}

function check_distro() {
	# currently only for Ubuntu 16.04
	if [[ -r /etc/os-release ]]; then
		. /etc/os-release
		if [[ "${VERSION_ID}" != "16.04" ]]; then
			echo "This script only supports ubuntu 16.04 LTS, exiting."
			exit 1
		fi
	else
		# no, thats not ok!
		echo "This script only supports ubuntu 16.04 LTS, exiting."	
		exit 1
	fi
}

function install_packages() {
	# development and build packages
	# these are common on all cryptos
	echo "* Package installation!"
	apt-get -qq update
	apt-get -qqy -o=Dpkg::Use-Pty=0 install build-essential g++ \
	protobuf-compiler libboost-all-dev autotools-dev \
    automake libcurl4-openssl-dev libboost-all-dev libssl-dev libdb++-dev \
    make autoconf automake libtool git apt-utils libprotobuf-dev pkg-config \
    libcurl3-dev libudev-dev libqrencode-dev bsdmainutils pkg-config libssl-dev \
    libgmp3-dev libevent-dev jp2a pv 	&>> ${SCRIPT_LOGFILE}
}

function swaphack() { 
#check if swap is available
if [ $(free | awk '/^Swap:/ {exit !$2}') ] || [ ! -f "/var/mnode_swap.img" ];then
	echo "* No proper swap, creating it" 
	# needed because ant servers are ants
	rm -f /var/mnode_swap.img
	dd if=/dev/zero of=/var/mnode_swap.img bs=1024k count=${MNODE_SWAPSIZE} &>> ${SCRIPT_LOGFILE}
	chmod 0600 /var/mnode_swap.img 
	mkswap /var/mnode_swap.img &>> ${SCRIPT_LOGFILE}
	swapon /var/mnode_swap.img &>> ${SCRIPT_LOGFILE} 
	echo '/var/mnode_swap.img none swap sw 0 0' | tee -a /etc/fstab &>> ${SCRIPT_LOGFILE}
	echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo 'vm.vfs_cache_pressure=50' | tee -a /etc/sysctl.conf		
else
	echo "* All good, we have a swap"	
fi
}

function create_mn_user() {

    # our new mnode unpriv user acc is added 
    if id "${MNODE_USER}" >/dev/null 2>&1; then
        echo "user exists already, do nothing" &>> ${SCRIPT_LOGFILE}
    else
        echo "Adding new system user ${MNODE_USER}"
        adduser --disabled-password --gecos "" ${MNODE_USER} &>> ${SCRIPT_LOGFILE}
    fi
    
}

function create_mn_dirs() {

    # individual data dirs for now to avoid problems
    echo "* Creating masternode directories"
    mkdir -p ${MNODE_CONF_BASE}
	for NUM in $(seq 1 ${count}); do
	    if [ ! -d "${MNODE_DATA_BASE}/${CODENAME}${NUM}" ]; then
	         echo "creating data directory ${MNODE_DATA_BASE}/${CODENAME}${NUM}" &>> ${SCRIPT_LOGFILE}
             mkdir -p ${MNODE_DATA_BASE}/${CODENAME}${NUM} &>> ${SCRIPT_LOGFILE}
        fi
	done    
	
}

function configure_firewall() {

    echo "* Configuring firewall rules"
	# disallow everything except ssh and masternode inbound ports
	ufw default deny                          &>> ${SCRIPT_LOGFILE}
	ufw logging on
	ufw allow ${SSH_INBOUND_PORT}/tcp         &>> ${SCRIPT_LOGFILE}
	# KISS, its always the same port for all interfaces
	ufw allow ${MNODE_INBOUND_PORT}/tcp       &>> ${SCRIPT_LOGFILE}
	# This will only allow 6 connections every 30 seconds from the same IP address.
	ufw limit OpenSSH	                      &>> ${SCRIPT_LOGFILE}
	ufw --force enable                        &>> ${SCRIPT_LOGFILE}
	echo "* Firewall ufw is active and enabled on system startup"

}

function validate_netchoice() {

    echo "* Validating network rules"		

	# break here of net isn't 4 or 6 
	if [ ${net} -ne 4 ] && [ ${net} -ne 6 ]; then
		echo "invalid NETWORK setting, can only be 4 or 6!"
		exit 1;
	fi 

	# generate the required ipv6 config
	if [ "${net}" -eq 4 ]; then
	    IPV6_INT_BASE="#NEW_IPv4_ADDRESS_FOR_MASTERNODE_NUMBER"
	    NETWORK_BASE_TAG=""
        echo "IPv4 address generation needs to be done manually atm!"  &>> ${SCRIPT_LOGFILE}
	fi	# end ifneteq4		    

}

function create_mn_configuration() {
    
        # create one config file per masternode
        for NUM in $(seq 1 ${count}); do
        PASS=$(date | md5sum | cut -c1-24)

			# we dont want to overwrite an existing config file
			if [ ! -f ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf ]; then
                echo "individual masternode config doesn't exist, generate it!" &>> ${SCRIPT_LOGFILE}
                
				# if a template exists, use this instead of the default
				if [ -e config/${CODENAME}/${CODENAME}.conf ]; then
					echo "custom configuration template for ${CODENAME} found, use this instead"
					cp ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
				else
					echo "No ${CODENAME} template found, using the default configuration template"			
					cp ${SCRIPTPATH}/config/default.conf ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf
				fi
				# replace placeholders
				echo "running sed on file ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf"
				sed -e "s/XXX_GIT_PROJECT_XXX/${CODENAME}/" -e "s/XXX_NUM_XXX/${NUM}]/" -e "s/XXX_PASS_XXX/${PASS}/" -e "s/XXX_IPV6_INT_BASE_XXX/[${IPV6_INT_BASE}/" -e "s/XXX_NETWORK_BASE_TAG_XXX/${NETWORK_BASE_TAG}/" -e "s/XXX_MNODE_INBOUND_PORT_XXX/${MNODE_INBOUND_PORT}/" -i ${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf				   
			fi        			
        done
        
}

function create_control_configuration() {

    rm -f /tmp/${CODENAME}_masternode.conf &>> ${SCRIPT_LOGFILE}
	# create one line per masternode with the data we have
	for NUM in $(seq 1 ${count}); do
		cat >> /tmp/${CODENAME}_masternode.conf <<-EOF
			${CODENAME}MN${NUM} [${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}]:${MNODE_INBOUND_PORT} MASTERNODE_PRIVKEY_FOR_${CODENAME}MN${NUM} COLLATERAL_TX_FOR_${CODENAME}MN${NUM} OUTPUT_NO_FOR_${CODENAME}MN${NUM}	
		EOF
	done

}

function create_systemd_configuration() {

    echo "* (over)writing systemd config files for masternodes"
	# create one config file per masternode
	for NUM in $(seq 1 ${count}); do
	PASS=$(date | md5sum | cut -c1-24)
		echo "* (over)writing systemd config file ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service"  &>> ${SCRIPT_LOGFILE}
		cat > ${SYSTEMD_CONF}/${CODENAME}_n${NUM}.service <<-EOF
			[Unit]
			Description=${CODENAME} distributed currency daemon
			After=network.target
                 
			[Service]
			User=${MNODE_USER}
			Group=${MNODE_USER}
         	
			Type=forking
			PIDFile=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid
			ExecStart=${MNODE_DAEMON} -daemon -pid=${MNODE_DATA_BASE}/${CODENAME}${NUM}/${CODENAME}.pid \
			-conf=${MNODE_CONF_BASE}/${CODENAME}_n${NUM}.conf -datadir=${MNODE_DATA_BASE}/${CODENAME}${NUM}
       		 
			Restart=always
			RestartSec=5
			PrivateTmp=true
			TimeoutStopSec=60s
			TimeoutStartSec=5s
			StartLimitInterval=120s
			StartLimitBurst=15
         	
			[Install]
			WantedBy=multi-user.target			
		EOF
	done

}

function set_permissions() {

	# maybe add a sudoers entry later
	chown -R ${MNODE_USER}:${MNODE_USER} ${MNODE_CONF_BASE} ${MNODE_DATA_BASE} &>> ${SCRIPT_LOGFILE}	

}

function wipe_all() {
    
    echo "Deleting all ${project} related data!" 
	rm -f /etc/masternodes/${project}_n*.conf 
	rmdir --ignore-fail-on-non-empty -p /var/lib/masternodes/${project}*
	rm -f /etc/systemd/system/${project}_n*.service
	rm -f ${MNODE_DAEMON}
	echo "DONE!"
	exit 0

}

function cleanup_after() {

	apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoremove
	apt-get -qqy -o=Dpkg::Use-Pty=0 --force-yes autoclean

	echo "kernel.randomize_va_space=1" > /etc/sysctl.conf  &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.rp_filter=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.accept_source_route=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.icmp_echo_ignore_broadcasts=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.default.log_martians=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv6.conf.all.accept_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.conf.all.send_redirects=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "kernel.sysrq=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.tcp_timestamps=0" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	echo "net.ipv4.tcp_syncookies=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE} 
	echo "net.ipv4.icmp_ignore_bogus_error_responses=1" >> /etc/sysctl.conf &>> ${SCRIPT_LOGFILE}
	sysctl -p
	
}

# source the default and desired crypto configuration files
function source_config() {

    SETUP_CONF_FILE="${SCRIPTPATH}/config/${project}/${project}.env" 

    # first things first, to break early if things are missing or weird
    check_distro
        
	if [ -f ${SETUP_CONF_FILE} ]; then
		#echo "read default config"	
		#source config/default.env
		echo "Script version ${SCRIPT_VERSION}, you picked: ${project}"
		echo "apply config file for ${project}"	&>> ${SCRIPT_LOGFILE}	
		source "${SETUP_CONF_FILE}"

		# count is from the default config but can ultimately be
		# overwritten at runtime
		if [ -z "${count}" ]
		then
			count=${SETUP_MNODES_COUNT}
			echo "No number given, installing default number of nodes: ${SETUP_MNODES_COUNT}" &>> ${SCRIPT_LOGFILE}
		fi

		# release is from the default project config but can ultimately be
		# overwritten at runtime
		if [ -z "$release" ]
		then
			release=${SCVERSION}
			echo "release empty, setting to project default: ${SCVERSION}"  &>> ${SCRIPT_LOGFILE}
		fi

		# net is from the default config but can ultimately be
		# overwritten at runtime
		if [ -z "${net}" ]; then
			net=${NETWORK_TYPE}
			echo "net EMPTY, setting to default: ${NETWORK_TYPE}" &>> ${SCRIPT_LOGFILE}
		fi			 			

		# main block of function logic starts here
	    # if update flag was given, delete the old daemon binary first & proceed
		if [ "$update" -eq 1 ]; then
			echo "update given, deleting the old daemon NOW!" &>> ${SCRIPT_LOGFILE}
			rm -f ${MNODE_DAEMON}  	 
		fi

		echo "************************* Installation Plan *****************************************"
		echo "I am going to install and configure ${count} ${project} masternodes for you now."
		echo "You have to add your masternode private key to the individual config files afterwards"
		echo ""
		echo "Stay tuned!"
        echo ""
		# show a hint for MANUAL IPv4 configuration
		if [ "${net}" -eq 4 ]; then
			NETWORK_TYPE=4
			echo "WARNING:"
			echo "You selected IPv4 for networking but there is no automatic workflow for this part."
			echo "This means you will have some mamual work to do to after this configuration run."
			echo ""
			echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
			echo "${IPV4_DOC_LINK}"
		fi	
		echo ""
		echo "A logfile for this run can be found at the following location:"
		echo "${SCRIPT_LOGFILE}"
		echo "*************************************************************************************"
		sleep 3
		
		# main routine
        prepare_mn_interfaces
        swaphack
        install_packages	
		build_mn_from_source
		create_mn_user
		create_mn_dirs
		configure_firewall      
		create_mn_configuration
		create_control_configuration
		create_systemd_configuration 
		set_permissions
		cleanup_after
		showbanner
		final_call 		
	else
		echo "required file ${SETUP_CONF_FILE} does not exist, abort!"
		exit 1   
	fi
	
}

function build_mn_from_source() {
        # daemon not found compile it
        if [ ! -f ${MNODE_DAEMON} ]; then
                mkdir -p ${SCRIPTPATH}/${CODE_DIR} &>> ${SCRIPT_LOGFILE}
                # if code directory does not exists, we create it clone the src
                if [ ! -d ${SCRIPTPATH}/${CODE_DIR}/${CODENAME} ]; then
                        mkdir -p ${CODE_DIR} && cd ${SCRIPTPATH}/${CODE_DIR} &>> ${SCRIPT_LOGFILE}
                        git clone ${GIT_URL} ${CODENAME}          &>> ${SCRIPT_LOGFILE}
                        cd ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}  &>> ${SCRIPT_LOGFILE}
                        echo "* Checking out desired GIT tag: ${release}"   
                        git checkout ${release}                   &>> ${SCRIPT_LOGFILE}
                else
                        echo "* Updating the existing GIT repo"
                        cd ${SCRIPTPATH}/${CODE_DIR}/${CODENAME}  &>> ${SCRIPT_LOGFILE}
                        git pull                                  &>> ${SCRIPT_LOGFILE}
                        echo "* Checking out desired GIT tag: ${release}"                      
                        git checkout ${release}                   &>> ${SCRIPT_LOGFILE}
                fi

                # print ascii banner if a logo exists
                echo -e "* Starting the compilation process for ${CODENAME}, stay tuned"
                if [ -f "${SCRIPTPATH}/assets/$CODENAME.jpg" ]; then
                        jp2a -b --colors --width=56 ${SCRIPTPATH}/assets/${CODENAME}.jpg     
                fi  
                # compilation starts here
                source ${SCRIPTPATH}/config/${CODENAME}/${CODENAME}.compile | pv -t -i0.1
        else
                echo "* Daemon already in place at ${MNODE_DAEMON}, not compiling"
        fi
}

function final_call() {
	# note outstanding tasks that need manual work
    echo "************! ALMOST DONE !******************************"	
	echo "There is still work to do in the configuration templates."
	echo "These are located at ${MNODE_CONF_BASE}, one per masternode."
	echo "Add your masternode private keys now."
	echo "eg in /etc/masternodes/${CODENAME}_n1.conf"
	echo ""
	echo "last but not least, run /usr/local/bin/activate_masternodes_pivx as root"	

    # place future helper script accordingly
    cp ${SCRIPTPATH}/scripts/activate_masternodes.sh ${MNODE_HELPER}_${CODENAME}
	echo "">> ${MNODE_HELPER}_${CODENAME}
	
	for NUM in $(seq 1 ${count}); do
		echo "systemctl enable ${CODENAME}_n${NUM}" >> ${MNODE_HELPER}_${CODENAME}
		echo "systemctl restart ${CODENAME}_n${NUM}" >> ${MNODE_HELPER}_${CODENAME}
	done
     
	chmod u+x ${MNODE_HELPER}_${CODENAME}
	tput sgr0
}


function prepare_mn_interfaces() {
    
    IPV6_INT_BASE="$(ip -6 addr show dev ${ETH_INTERFACE} | grep inet6 | awk -F '[ \t]+|/' '{print $3}' | grep -v ^fe80 | grep -v ^::1 | cut -f1-4 -d':' | head -1)"
	
	validate_netchoice
	echo "IPV6_INT_BASE AFTER : ${IPV6_INT_BASE}" &>> ${SCRIPT_LOGFILE}

    # user opted for ipv6 (default), so we have to check for ipv6 support	
	# check for vultr ipv6 box active
	if [ -z "${IPV6_INT_BASE}" ] && [ ${net} -ne 4 ]; then
		echo "No IPv6 support on the VPS but IPv6 is the setup default. Please switch to ipv4 with flag \"-n 4\" if you want to continue."
		echo ""
		echo "See the following link for instructions how to add multiple ipv4 addresses on vultr:"
		echo "${IPV4_DOC_LINK}"
		exit 1
	fi	
		
	# generate the required ipv6 config
	if [ "${net}" -eq 6 ]; then
        # vultr specific, needed to work
	    sed -ie '/iface ${ETH_INTERFACE} inet6 auto/s/^/#/' ${NETWORK_CONFIG}
	    
		# move current config out of the way first
		cp ${NETWORK_CONFIG} ${NETWORK_CONFIG}.${DATE_STAMP}.bkp

		# create the additional ipv6 interfaces, rc.local because it's more generic 	    
		for NUM in $(seq 1 ${count}); do

			# check if the interfaces exist	    
			ip -6 addr | grep -qi "${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}"
			if [ $? -eq 0 ]
			then
			  echo "IP for masternode already exists, skipping creation" &>> ${SCRIPT_LOGFILE}
			else
			  echo "Creating new IP address for ${CODENAME} masternode nr ${NUM}" &>> ${SCRIPT_LOGFILE}
			  echo "ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE}" >> ${NETWORK_CONFIG}
			  sleep 2
			  ip -6 addr add ${IPV6_INT_BASE}:${NETWORK_BASE_TAG}::${NUM}/64 dev ${ETH_INTERFACE} &>> ${SCRIPT_LOGFILE}
			fi	
		done # end forloop	    
	fi # end ifneteq6
	
}

##################------------Menu()---------#####################################

# Declare vars. Flags initalizing to 0.
wipe=0;
debug=0;
update=0;

# Execute getopt
ARGS=$(getopt -o "hp:n:c:r:wud" -l "help,project:,net:,count:,release:,wipe,update,debug" -n "install.sh" -- "$@");
 
#Bad arguments
if [ $? -ne 0 ];
then
    help;
fi
 
eval set -- "$ARGS";
 
while true; do
    case "$1" in
        -h|--help)
            shift;
            help;
            ;;
        -p|--project)
            shift;
                    if [ -n "$1" ]; 
                    then
                        project="$1";
                        shift;
                    fi
            ;;
        -n|--net)
            shift;
                    if [ -n "$1" ]; 
                    then
                        net="$1";
                        shift;
                    fi
            ;;
        -c|--count)
            shift;
                    if [ -n "$1" ]; 
                    then
                        count="$1";
                        shift;
                    fi
            ;;
        -r|--release)
            shift;
                    if [ -n "$1" ]; 
                    then
                        release="$1";
                        shift;
                    fi
            ;;
        -w|--wipe)
            shift;
                    wipe="1";
            ;;
        -u|--update)
            shift;
                    update="1";
            ;;
        -d|--debug)
            shift;
                    debug="1";
            ;;            
 
        --)
            shift;
            break;
            ;;
    esac
done
 
# Check required arguments
if [ -z "$project" ]
then
    show_help;
fi

# Check required arguments
if [ "$wipe" -eq 1 ]; then
	get_confirmation "Would you really like to WIPE ALL DATA!? YES/NO y/n" && wipe_all
	exit 0
fi		
 
## Iterate over rest arguments called $arg
# for arg in "$@"
# do
#     # Your code here (remove example below)
#     echo $arg
#  
# done

#################################################
# source default config before everything else
source ${SCRIPTPATH}/config/default.env
#################################################

main() {

    echo "starting" &> ${SCRIPT_LOGFILE}
    showbanner
    
	# debug
	if [ "$debug" -eq 1 ]; then
		echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
		echo "START DEFAULTS => "
		echo "SCRIPT_VERSION:       $SCRIPT_VERSION"
		echo "SSH_INBOUND_PORT:     ${SSH_INBOUND_PORT}"
		echo "SYSTEMD_CONF:         ${SYSTEMD_CONF}"
		echo "NETWORK_CONFIG:       ${NETWORK_CONFIG}"
		echo "NETWORK_TYPE:         ${NETWORK_TYPE}"	
		echo "ETH_INTERFACE:        ${ETH_INTERFACE}"
		echo "MNODE_CONF_BASE:      ${MNODE_CONF_BASE}"
		echo "MNODE_DATA_BASE:      ${MNODE_DATA_BASE}"
		echo "MNODE_USER:           ${MNODE_USER}"
		echo "MNODE_HELPER:         ${MNODE_HELPER}"
		echo "MNODE_SWAPSIZE:       ${MNODE_SWAPSIZE}"
		echo "CODE_DIR:             ${CODE_DIR}"
		echo "ETH_INTERFACE:        ${ETH_INTERFACE}"
		echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"	
		echo "END DEFAULTS => "
	fi
	
	# source project configuration         
    source_config ${project}
    
	# debug
	if [ "$debug" -eq 1 ]; then
		echo "START PROJECT => "
		echo "CODENAME:             $CODENAME"
		echo "SETUP_MNODES_COUNT:   ${SETUP_MNODES_COUNT}"
		echo "MNODE_DAEMON:         ${MNODE_DAEMON}"
		echo "MNODE_INBOUND_PORT:   ${MNODE_INBOUND_PORT}"
		echo "GIT_URL:              ${GIT_URL}"
		echo "SCVERSION:            ${SCVERSION}"
		echo "NETWORK_BASE_TAG:     ${NETWORK_BASE_TAG}"	
		echo "END PROJECT => "   	
		 
		echo "START OPTIONS => "
		echo "RELEASE: ${release}"
		echo "PROJECT: ${project}"
		echo "SETUP_MNODES_COUNT: ${count}"
		echo "NETWORK_TYPE: ${NETWORK_TYPE}"
		echo "NETWORK_TYPE: ${net}"         
	   
		echo "END OPTIONS => "
		echo "********************** VALUES AFTER CONFIG SOURCING: ************************"
	fi    
}

main "$@"
