#!/bin/bash
set -e

function printMessage {
  echo ">>" $1
}


function printHeader {
  echo "##############################"
  echo ">>" $1
  echo "##############################"
}

function detectOS()
{
    if grep -Eqii "CentOS" /etc/issue || grep -Eq "CentOS" /etc/*-release; then
        DISTRO='centos'
        PM='yum'
    elif grep -Eqi "Red Hat Enterprise Linux Server" /etc/issue || grep -Eq "Red Hat Enterprise Linux Server" /etc/*-release; then
        DISTRO='redhat'
        PM='yum'
    elif grep -Eqi "Aliyun" /etc/issue || grep -Eq "Aliyun" /etc/*-release; then
        DISTRO='fliyun'
        PM='yum'
    elif grep -Eqi "Fedora" /etc/issue || grep -Eq "Fedora" /etc/*-release; then
        DISTRO='fedora'
        PM='yum'
    elif grep -Eqi "Debian" /etc/issue || grep -Eq "Debian" /etc/*-release; then
        DISTRO='debian'
        PM='apt'
    elif grep -Eqi "Deepin" /etc/issue || grep -Eq "Deepin" /etc/*-release; then
        DISTRO='Deepin'
        PM='apt'
    elif grep -Eqi "Ubuntu" /etc/issue || grep -Eq "Ubuntu" /etc/*-release; then
        DISTRO='ubuntu'
        PM='apt'
    elif grep -Eqi "Raspbian" /etc/issue || grep -Eq "Raspbian" /etc/*-release; then
        DISTRO='Raspbian'
        PM='apt'
    else
        DISTRO='unknown'
    fi
}

function package_exists() {
    return dpkg -l "$1" &> /dev/null
}

function installDocker {
    if [ -x "$(command -v docker)" ]; then
        echo '[✔] Docker is already installed.'
    else
        apt update
        apt upgrade -y
        #apt remove docker docker-engine docker.io

        if package_exists docker ; then
            apt remove docker;
        fi

        if package_exists docker-engine ; then
            apt remove docker;
        fi

        if package_exists docker.io ; then
            apt remove docker;
        fi

        apt install \
           apt-transport-https \
           ca-certificates \
           curl \
           gnupg2 \
           software-properties-common -y
        printHeader "Installing Docker"
        curl -fsSL https://download.docker.com/linux/$DISTRO/gpg | apt-key add -
        add-apt-repository \
         "deb [arch=amd64] https://download.docker.com/linux/$DISTRO \
         $(lsb_release -cs) \
         stable"
        apt update
        apt install docker-ce -y
    fi
}

function installDockerCompose {
    if [ -x "$(command -v docker-compose)" ]; then
        echo '[✔] Docker Compose is already installed.'
    else
        printHeader "Installing Docker Compose"
        curl -L https://github.com/docker/compose/releases/download/1.21.2/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}


function setupDockerGateway {
  local GATEWAY_DIR='/docker/docker-gateway'
  if [ -d "$GATEWAY_DIR" ]; then
      echo '[✔] Docker gateway is already installed., for update try `git pull` in' $GATEWAY_DIR
  else
    printHeader "Configuring Docker Gateway"
    # install git
    apt install git -y

    # clone configuration for gateway
    mkdir -p $GATEWAY_DIR
    git clone https://github.com/goodservers/docker-gateway.git $GATEWAY_DIR

  fi
}

function runDockerGateway {
    # create network which connects the containers
    docker network create nginx-proxy
    # run docker gateway
    cd $GATEWAY_DIR; docker-compose up -d
}

function setupDockerUser {
    local USER='user'
    local USER_DIR=/home/$USER

    if [ -d $USER_DIR ]; then
        echo '[✔] User is already installed.'
    else
        printHeader "Configuring user to be used by Docker Gateway"

        # prepare user which runs in containers (Docker security)
        useradd $USER
        echo "$USER:x:1001:1001:,,,:$USER_DIR:/bin/bash" >>/etc/passwd
        echo "$USER:!:15392:0:99999:7:::" >>/etc/shadow

        mkdir -p $USER_DIR/.ssh/
        echo "#Here place your public ssh key" > $USER_DIR/.ssh/authorized_keys

        # set users permission to his homedir
        chown -Rc $USER:$USER $USER_DIR

        # add rights to run docker
        usermod -aG docker $USER
    fi
}


function setupUserSSHKey {
    local USER='user'
    local USER_DIR=/home/$USER
    # setup ssh key
    echo 'Do you want to upload your public key or generate new private key?'
    select yn in 'Upload public' 'Generate new private key'; do
      case $yn in
          'Upload public' ) nano +10 $USER_DIR/.ssh/authorized_keys; break;;
          'Generate new private key' )
        ssh-keygen -f $USER_DIR/.ssh/deploy.guide.key -t rsa -b 4096 -C 'deploy@deploy.guide' -P ''
        cat $USER_DIR/.ssh/deploy.guide.key.pub >> $USER_DIR/.ssh/authorized_keys
        echo "Copy your private key (it will be visible just for now):"
        cat $USER_DIR/.ssh/deploy.guide.key
        rm $USER_DIR/.ssh/deploy.guide.key
      break;;
      esac
    done
}

function disableSSHDPassword {
  # Disable password login
  sed -i '/PasswordAuthentication/s/yes/no/g' /etc/ssh/sshd_config

  # Restart sshd
  sudo service ssh restart

  printMessage "PasswordAuthentication was disabled"
}

function guide {

  printHeader "Do you want to install Docker?"
  select yn in "Yes" "No"; do
      case $yn in
          'Yes' ) installDocker; break;;
          'No' )
      break;;
      esac
  done


  printHeader "Do you want to install Docker Compose?"
  select yn in "Yes" "No"; do
      case $yn in
          'Yes' ) installDockerCompose; break;;
          'No' )
      break;;
      esac
  done


  printHeader "Do you want to setup Docker Gateway?"
  select yn in "Yes" "No"; do
      case $yn in
          'Yes' ) setupDockerGateway; break;;
          'No' )
      break;;
      esac
  done

  printHeader "Do you want to start Docker Gateway?"
  select yn in "Yes" "No"; do
      case $yn in
          'Yes' ) runDockerGateway; break;;
          'No' )
      break;;
      esac
  done

  printHeader "Do you want to setup user for Docker gateway?"
  select yn in "Yes" "No"; do
      case $yn in
          'Yes' ) setupDockerUser; setupUserSSHKey; break;;
          'No' )
      break;;
      esac
  done

}

# OPTS=`getopt -o vh: --long verbose,dry-run,help,stack-size: -n 'parse-options' "$@"`

# if [ $? != 0 ] ; then echo "Failed parsing options." >&2 ; exit 1 ; fi

# echo "$OPTS"
# eval set -- "$OPTS"

# HELP=false
# GUIDE=false
# TEST=false

# while true; do
#   case "$1" in
#     -h | --help )    HELP=true; shift ;;
#     -g | --guide )    GUIDE=true; shift ;;
#     -t | --test ) TEST=true; shift ;;
#     * ) break ;;
#   esac
# done


options=$(getopt -o hgt --long color: -- "$@")
[ $? -eq 0 ] || {
    echo "Incorrect options provided"
    exit 1
}
eval set -- "$options"
while true; do
    case "$1" in
    -h)
      HELP=true;
      ;;

    -g)
      GUIDE=true;
      ;;
    -t)
      TEST=true;
      ;;
    --color)
        shift; # The arg is next in position args
        COLOR=$1
        [[ ! $COLOR =~ BLUE|RED|GREEN ]] && {
            echo "Incorrect options provided"
            exit 1
        }
        ;;
    --)
        shift
        break
        ;;
    esac
    shift
done


detectOS

if [ $TEST ]; then
  installDocker
  installDockerCompose
  setupDockerGateway
  setupDockerUser
elif [ $GUIDE ]; then
  guide
else
  installDocker
  installDockerCompose
  setupDockerGateway
  runDockerGateway
  setupDockerUser
fi

set +e
