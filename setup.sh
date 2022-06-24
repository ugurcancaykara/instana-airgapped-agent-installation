#!/bin/bash
set -o pipefail

AGENT_DIR="/opt/instana/agent"
# AIX, Darwin, Linux, SunOS
OS=$(uname -s)
MACHINE=""
FAMILY="unknown"
INIT="sysv"

PKG_URI=packages.instana.io

AGENT_TYPE="dynamic"
PROMPT=true
START=false
MODE="apm"
INSTANA_AGENT_SYSTEMD_TYPE=simple
INSTANA_AGENT_HOST=ksapm.kocsistem.com.tr
INSTANA_AGENT_PORT=1444


gpg_check=1

function log_info {
  local message=$1

  if [[ $TERM == *"color"* ]]; then
    echo -e "\e[32m$message\e[0m"
  else
    echo $message
  fi
}

function detect_family() {
  if which apt-get &> /dev/null; then
    FAMILY="apt"
    return 0
  fi

  if type yum &>/dev/null
  then
    FAMILY="yum"
    return 0
  fi
}

function detect_init() {
  if ls -l /sbin/init | grep systemd &> /dev/null; then
    INIT="systemd"
    return 0
  fi

  if /sbin/init --version | grep upstart &> /dev/null; then
    INIT="upstart"
    return 0
  fi
}

function detect_machine() {
  if [ "$OS" = "AIX" ]; then
    MACHINE=$(uname -p)
  elif [ "$OS" = "Darwin" ]; then
    MACHINE=$(uname -m)
  elif [ "$OS" = "Linux" ]; then
    MACHINE=$(uname -m)
  elif [ "$OS" = "SunOS" ]; then
    MACHINE=$(uname -m)
  else
    log_info "Could not detect machine for OS: $OS"
    MACHINE="unknown"
  fi
}

function setup_agent() {

  echo $FAMILY
  case "$FAMILY" in


  'apt')
  echo "running debian installation"
  dpkg -i $INSTANA_PACKAGE_PATH

  ;;
  'yum')
  echo "running rhel installation"
  rpm -i $INSTANA_PACKAGE_PATH

  esac
}

function configure_mode() {
  if [ "${MODE}" = 'apm' ]; then
    /bin/cp "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg.template" "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"
    echo "mode = APM" >> "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"

    return 0
  fi

  if [ "${MODE}" = 'aws' ]; then
    log_info 'Configuring AWS mode'
    # Get region from metadata endpoint


    ROLES_FOUND=false

    if download_to_stdout http://169.254.169.254/latest/meta-data/iam/security-credentials/ > /dev/null 2>&1; then
      ROLES_FOUND=true
    fi

    if [ "$ROLES_FOUND" = "false" ]; then
      if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        log_error "AWS_ACCESS_KEY_ID and/or AWS_SECRET_ACCESS_KEY not exported, and no IAM instance role detected to allow AWS API access."
        exit 1
      fi
    fi

    /bin/cp "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg.template" "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"
    echo "mode = INFRASTRUCTURE" >> "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"

    return 0
  fi

  if [ "$MODE" = "infra" ]; then
    /bin/cp "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg.template" "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"
    echo "mode = INFRASTRUCTURE" >> "${AGENT_DIR}/etc/instana/com.instana.agent.main.config.Agent.cfg"

    return 0
  fi
}

function log_error {
  local message=$1

  if [[ $TERM == *"color"* ]]; then
    echo -e "\e[31m$message\e[0m"
  else
    echo $message
  fi
}



function configure_multibackend(){


    /bin/cp "${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend.cfg" "${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend-1.cfg"
    /bin/cp "${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend.cfg" "${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend-2.cfg"
    /bin/rm "${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend.cfg"

    sed -i "s/host=.*/host=${INSTANA_AGENT_HOST_ONE}/g" ${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend-1.cfg
    sed -i "s/host=.*/host=${INSTANA_AGENT_HOST_TWO}/g" ${AGENT_DIR}/etc/instana/com.instana.agent.main.sender.Backend-2.cfg

}

# -z <zone_name>
function configure_zone(){

    cat <<EOF >> ${AGENT_DIR}/etc/instana/configuration.yaml
com.instana.plugin.generic.hardware:
  enabled: true
  availability-zone: '${INSTANA_AGENT_ZONE}'
EOF

}

function configure_mvn_conf(){
    /bin/cp "${INSTANA_MVN_PATH}" "${AGENT_DIR}/etc/instana/mvn-settings.xml"
}

function configure_tag(){

cat <<EOF >> ${AGENT_DIR}/etc/instana/configuration.yaml
com.instana.plugin.host:
  tags:
    - '${INSTANA_AGENT_TAG}'
EOF

}

function update_custom_systemd_unit_file () {
  # file does not exists -> new installation indicator
  if [ "$INIT" = "systemd" ] && [ ! -e /lib/systemd/system/instana-agent.service ]; then
    mkdir -p /etc/systemd/system/instana-agent.service.d/
    local systemd_custom_start_conf
    read -r -d '' systemd_custom_start_conf <<EOF
[Service]
Type=$INSTANA_AGENT_SYSTEMD_TYPE
EOF

    if ! echo "$systemd_custom_start_conf" > /etc/systemd/system/instana-agent.service.d/agent-custom-start.conf; then
      log_warn "Failed to create '/etc/systemd/system/instana-agent.service.d/agent-custom-start.conf'"
    fi

  fi
}


function start_agent() {
  START=true
  if [ $START = false ]; then
    return 0
  fi

  if [ "$INIT" = "systemd" ]; then
    if ! systemctl enable instana-agent > /dev/null 2>&1; then
      log_error "Instana agent service enable on boot failed"
      exit 1
    else
      log_info "Instana agent enabled on boot"
    fi

    log_info "Starting instana-agent"
    if ! systemctl restart instana-agent > /dev/null 2>&1; then
      log_error "Instana agent service start failed"
      exit 1
    fi
  else
    log_warn "Instana agent automatic enable/startup by this script is only supported for systemd"
    log_warn "Utilize your distribution's init system methods to enable/start the agent"
  fi
}

while getopts "syjinl:e:t:m:a:d:i:z:g:b:u:p:" opt; do
  case $opt in
    a)
      INSTANA_AGENT_KEY=$OPTARG
      ;;
    d)
      INSTANA_DOWNLOAD_KEY=$OPTARG
      ;;
    e)
      INSTANA_AGENT_HOST_ONE=$OPTARG
      ;;
    g)
      INSTANA_AGENT_HOST_TWO=$OPTARG
      ;;
    m)
      MODE=$OPTARG
      ;;
    n)
      INSTANA_AGENT_SYSTEMD_TYPE=notify
      ;;
    p)
      INSTANA_PACKAGE_PATH=$OPTARG
      ;;
    u)
      INSTANA_MVN_PATH=$OPTARG
      ;;
    t)
      INSTANA_AGENT_TAG=$OPTARG
      ;;
    z)
      INSTANA_AGENT_ZONE=$OPTARG
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ "$(id -u)" != "0" ]; then
  log_error "This script must be executed as a user with root privileges"
  exit 1
fi

if [ "$OS" = "Darwin" ]; then
  log_error "Agent install script does not support macOS. Please download the macOS package from the 'Installing Instana Agents' wizard."
  exit 1
fi

if [ "$OS" = "AIX" ]; then
  log_error "Agent install script does not support AIX. Please download the AIX package from the 'Installing Instana Agents' wizard."
  exit 1
fi

if [ "$OS" = "SunOS" ]; then
  log_error "Agent install script does not support Solaris. Please download the Solaris package from the 'Installing Instana Agents' wizard."
  exit 1
fi

detect_machine

if [ $MACHINE != "x86_64" ] && [ $MACHINE != "aarch64" ] && [ $MACHINE != "s390x" ] && [ $MACHINE != "ppc64le" ]; then
  log_error "Systems architecture: $MACHINE not supported"
  exit 1
fi

if [ ! "$INSTANA_AGENT_KEY" ]; then
  echo "-a INSTANA_AGENT_KEY required!"
  exit 1
fi

if [ ! "$INSTANA_DOWNLOAD_KEY" ]; then
  INSTANA_DOWNLOAD_KEY="$INSTANA_AGENT_KEY"
fi

if [ $AGENT_TYPE != "static" ] && [ $AGENT_TYPE != "dynamic" ]; then
  log_error "Invalid agent type specified $AGENT_TYPE"
  exit 1
fi


if [ "$MODE" != "apm" ] && [ "$MODE" != "aws" ] && [ "$MODE" != "infra" ]; then
  log_error "Invalid mode specified. Supported modes: apm | aws | infra."
  exit 1
fi

if [ ! "$INSTANA_DOWNLOAD_KEY" ]; then
  INSTANA_DOWNLOAD_KEY="$INSTANA_AGENT_KEY"
fi

detect_family

detect_init

echo "Setting up the ${AGENT_TYPE} Instana agent for $OS"


export INSTANA_AGENT_KEY
export INSTANA_DOWNLOAD_KEY
export INSTANA_AGENT_HOST
export INSTANA_AGENT_PORT


update_custom_systemd_unit_file

if ! setup_agent; then
  exit 1
fi

configure_mode


if [ ! -z "$INSTANA_AGENT_HOST_ONE" ] && [ ! -z "$INSTANA_AGENT_HOST_TWO" ]  ; then
  configure_multibackend
fi

if [ ! -z "$INSTANA_AGENT_ZONE" ]; then
  configure_zone
fi

if [ ! -z "$INSTANA_AGENT_TAG" ]; then
  configure_tag
fi

if [ ! -z "$INSTANA_MVN_PATH" ]; then
  configure_mvn_conf
fi
if ! start_agent; then
  exit 1
fi