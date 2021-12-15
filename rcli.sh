#!/bin/bash
# rcli - simplified installation and switching between R versions
# Copyright (C) 2021 - 2021 Patrick Schratz

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

# shellcheck shell=bash
# execute script with bash (shebang line is /bin/sh for portability)
# if [ -z "$BASH_VERSION" ]; then
#   exec bash "$0" "$@"
# fi

if [[ $1 == "" ]]; then
  showInfo() {
    # `cat << EOF` This means that cat should stop reading when EOF is detected
    cat <<EOF
Usage: rcli [-h] [-v] [subcommand] <R version> [--arch ARCHITECTURE]

Available commands:
    install     Install an R version
    switch      Switch between installed R versions
    list        List installed R versions

EOF
    # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
  }

  showInfo
  exit 0

elif [[ $1 == "--version" || $1 == "-v" ]]; then
  echo "0.2.0"
  exit 0

elif [[ $1 == "--help" || $1 == "-h" ]]; then
  showHelp() {
    # `cat << EOF` This means that cat should stop reading when EOF is detected
    cat <<EOF
Usage: rcli [-h] [-v] [subcommand] <R version> [--arch ARCHITECTURE]

-h, --help       Display this help.

--arch           Request a specific architecture. Only applies to macOS and only takes 'x86_64' as a valid input.

-v, --version    Return the version.

Examples:

rcli install 4.0.2
rcli install 4.1.0 --arch x86_64

rcli switch 4.0.2
rcli switch 4.1.0 --arch x86_64

rcli list

EOF
    # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
  }

  showHelp
  exit 0
fi

# pre-checks -------------------------------------------------------------------

if [[ $(uname) == "Darwin" ]]; then
  homebrew_r=$(brew info --json r | grep "linked" | xargs | cut -c 13-)
  if ! [[ $homebrew_r == "null," ]]; then
    echo -e "It looks like you installed R via the homebrew formula (instead of using the \033[36m--cask\033[0m option which provides the official CRAN installer). \033[36mrcli\033[0m is incompatible with the homebrew formula. To use \033[36mrcli\033[0m, please switch to the homebrew cask via \033[36mbrew remove r && brew install --cask r\033[0m."
    exit 0
  fi

  # if R is not installed at all yet, create frameworks dir
  if [[ $(test -d /Library/Frameworks/R.framework && echo "true" || echo "false") == "false" ]]; then
    echo -e "\033[36mrcli\033[0m requires R to be installed (which is not the case it seems). Please first install R, e.g. via homebrew by calling \033[36mbrew install --cask r\033[0m or by using the CRAN GUI installer".
    exit 0
  fi

fi

# Example:
# parseArguments "${@}"
# echo "${ARG_0}" -> package
# echo "${ARG_1}" -> install
# echo "${ARG_PACKAGE}" -> "name with space"
# echo "${ARG_BUILD}" -> 1 (true)
# echo "${ARG_ARCHIVE}" -> 1 (true)
function parseArguments() {
  PREVIOUS_ITEM=''
  COUNT=0
  for CURRENT_ITEM in "${@}"; do
    if [[ ${CURRENT_ITEM} == "--"* ]]; then
      printf -v "ARG_$(formatArgument "${CURRENT_ITEM}")" "%s" "1" # could set this to empty string and check with [ -z "${ARG_ITEM-x}" ] if it's set, but empty.
    else
      if [[ $PREVIOUS_ITEM == "--"* ]]; then
        printf -v "ARG_$(formatArgument "${PREVIOUS_ITEM}")" "%s" "${CURRENT_ITEM}"
      else
        printf -v "ARG_${COUNT}" "%s" "${CURRENT_ITEM}"
      fi
    fi

    PREVIOUS_ITEM="${CURRENT_ITEM}"
    ((COUNT++))
  done
}

# Format argument.
function formatArgument() {
  # ARGUMENT="${1^^}"           # Capitalize.
  ARGUMENT="${1/--/}"         # Remove "--".
  ARGUMENT="${ARGUMENT//-/_}" # Replace "-" with "_".
  # Explanation: because we need to work with bash v3.2, we cannot use the  ${1^^} syntax.
  # According to https://stackoverflow.com/questions/33324767/easiest-way-to-capitalize-a-string-within-bash-3-2 there is no simple way in bash 3.2 to capitalize
  # perl is installed by default on macOS, hence we use this way
  ARGUMENT=$(perl -C -lne 'print uc' <<<"$ARGUMENT")
  echo "${ARGUMENT}"
}

function switch() {

  if [[ $R_VERSION == "devel" ]]; then
    R_VERSION=$(curl -s https://mac.r-project.org/ | grep "Under development" -m 1 | grep "[0-9]\.[0-9]\.[0-9]" -o)
    R_CUT=$(echo $R_VERSION | cut -c 1-3)
  else
    R_CUT=$(echo $R_VERSION | cut -c 1-3)
  fi

  if [[ $(uname) == "Linux" ]]; then

    exists=$(test -d /opt/R/$R_VERSION && echo "true" || echo "false")

    if [[ $exists == "false" ]]; then
      echo -e "R version $R_VERSION does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION\033[0m."
      exit 0
    fi

    sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
    sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/bin/R
    sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript
    sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/bin/Rscript

    exit 0
  fi

  currentR=$(echo $(R -s -q -e 'paste(R.version[["major"]], R.version[["minor"]], sep = ".")') | cut -c 6-10)
  currentArch=$(R -s -q -e "Sys.info()[['machine']]" | cut -c 6- | sed 's/.$//')

  if [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then

    exists=$(test -d /opt/R/$R_VERSION-arm64 && echo "true" || echo "false")
    if [[ $exists == "false" ]]; then
      echo -e "R $R_VERSION does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION\033[0m."
      exit 0
    fi

    # only backup if the syslib contains user packages (i.e. n > 31)
    SYSLIB=$(R -q -s -e "tail(.libPaths())" | cut -c 6- | sed 's/.$//')
    if [[ $ARG_DEBUG == 1 ]]; then
      echo "DEBUG: Switching to arm64"
      echo "DEBUG: n(packages) in syslib: $(find $SYSLIB -maxdepth 1 -type d | wc -l | xargs)"
    fi

    if [[ $(find $SYSLIB -maxdepth 1 -type d | wc -l | xargs) > 31 ]]; then

      if [[ $currentArch == "arm64" ]]; then
        CURRENT_R_VERSION_ARCH=$currentR-$currentArch
      else
        CURRENT_R_VERSION_ARCH=$currentR
      fi

      if [[ $(arch) == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi
      if [[ $(arch) == "arm64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION-arm64
        TARGET_R_CUT_ARCH=$R_CUT-arm64
      fi
      # override with user preference
      if [[ $ARG_ARCH == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi

      sudo mkdir -p /opt/R/$currentR/syslib-bak
      sudo cp -fR $SYSLIB/* /opt/R/$CURRENT_R_VERSION_ARCH/syslib-bak

      sudo rm -rf /Library/Frameworks/R.framework/Versions/*
      sudo cp -fR /opt/R/$TARGET_R_VERSION_ARCH/ /Library/Frameworks/R.framework/Versions 2>/dev/null
      sudo cp -fR /opt/R/$TARGET_R_VERSION_ARCH/TARGET_R_CUT_ARCH/Resources /Library/Frameworks/R.framework/ 2>/dev/null

      # need 775 permissions
      sudo chmod 775 /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library

      # only restore if R_VERSION has a syslib-bak
      if [[ $(test -d /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak && echo "true" || echo "false") == "true" ]]; then
        sudo cp -fR /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak/ /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library
      fi

      # clean
      sudo rm -rf /Library/Frameworks/R.framework/Versions/syslib-bak

    else

      sudo rm -rf /Library/Frameworks/R.framework/Versions/*
      sudo cp -fR /opt/R/$R_VERSION-arm64/ /Library/Frameworks/R.framework/Versions 2>/dev/null
      sudo cp -fR /opt/R/$R_VERSION/$R_CUT-arm64/Resources /Library/Frameworks/R.framework/ 2>/dev/null

      if [[ $(arch) == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi
      if [[ $(arch) == "arm64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION-arm64
        TARGET_R_CUT_ARCH=$R_CUT-arm64
      fi
      # override with user preference
      if [[ $ARG_ARCH == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi

      # need 775 permissions
      sudo chmod 775 /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library

      ### restore syslib from target version if it exists
      # only restore if R_VERSION has a syslib-bak
      if [[ $(test -d /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak && echo "true" || echo "false") == "true" ]]; then
        sudo cp -fR /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library
      fi

      sudo rm -rf /Library/Frameworks/R.framework/Versions/syslib-bak
    fi

    exit 0

  else

    # -> X86 switch
    if [[ $ARG_DEBUG == 1 ]]; then
      echo "DEBUG: Switching: -> x86"
    fi

    exists=$(test -d /opt/R/$R_VERSION && echo "true" || echo "false")
    if [[ $ARG_ARCH == "x86_64" ]]; then

      if [[ $exists == "false" ]]; then
        echo -e "R version $R_VERSION for x86_64 architecture does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION --arch x86_64\033[0m."
        exit 0
      fi

      echo -e "→ Switching to \033[36m--arch x86_64\033[0m R installation because \033[36m--arch x86_64\033[0m was set."
    fi

    if [[ $exists == "false" ]]; then
      echo -e "R version $R_VERSION does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION\033[0m."
      exit 0
    fi

    if [[ $currentArch == "arm64" ]]; then
      CURRENT_R_VERSION_ARCH=$currentR-arm64
    else
      CURRENT_R_VERSION_ARCH=$currentR
    fi

    # only backup if the syslib contains user packages
    SYSLIB=$(R -q -s -e "tail(.libPaths())" | cut -c 6- | sed 's/.$//')

    if [[ $ARG_DEBUG == 1 ]]; then
      echo -e "DEBUG: n(packages) in syslib: $(ls $SYSLIB | wc -l | xargs)"
    fi

    if [[ $(find $SYSLIB -maxdepth 1 -type d | wc -l | xargs) > 31 ]]; then

      if [[ $ARG_DEBUG == 1 ]]; then
        echo -e "DEBUG: switch(): Backing up system libraries"
      fi

      sudo mkdir -p /opt/R/$CURRENT_R_VERSION_ARCH/syslib-bak
      sudo cp -fR $SYSLIB/ /opt/R/$CURRENT_R_VERSION_ARCH/syslib-bak

      sudo rm -rf /Library/Frameworks/R.framework/Versions/*
      sudo cp -fR /opt/R/$R_VERSION/ /Library/Frameworks/R.framework/Versions 2>/dev/null
      sudo cp -fR /opt/R/$R_VERSION/$R_CUT/Resources /Library/Frameworks/R.framework 2>/dev/null

      if [[ $(arch) == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi
      if [[ $(arch) == "arm64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION-arm64
        TARGET_R_CUT_ARCH=$R_CUT-arm64
      fi
      # override with user preference
      if [[ $ARG_ARCH == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      fi

      # need 775 permissions
      sudo chmod 775 /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library

      ### restore syslib from target version if it exists
      # only restore if R_VERSION has a syslib-bak
      if [[ $(test -d /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak && echo "true" || echo "false") == "true" ]]; then
        if [[ $ARG_DEBUG == 1 ]]; then
          echo -e "DEBUG: switch(): Restoring existing syslib"
        fi
        sudo cp -fR /opt/R/$TARGET_R_VERSION_ARCH/syslib-bak /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library
      fi

      # clean
      sudo rm -rf /Library/Frameworks/R.framework/Versions/syslib-bak

    else

      sudo rm -rf /Library/Frameworks/R.framework/Versions/*
      sudo cp -fR /opt/R/$R_VERSION/ /Library/Frameworks/R.framework/Versions 2>/dev/null
      sudo cp -fR /opt/R/$R_VERSION/$R_CUT/Resources /Library/Frameworks/R.framework/ 2>/dev/null

      if [[ $ARG_ARCH == "x86_64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      elif [[ $(arch) != "arm64" ]]; then
        TARGET_R_VERSION_ARCH=$R_VERSION
        TARGET_R_CUT_ARCH=$R_CUT
      else
        TARGET_R_VERSION_ARCH=$R_VERSION-arm64
        TARGET_R_CUT_ARCH=$R_CUT-arm64
      fi

      # need 775 permissions
      sudo chmod 775 /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library

      # only restore if R_VERSION has a syslib-bak
      if [[ $(test -d /opt/R/$R_VERSION/syslib-bak && echo "true" || echo "false") == "true" ]]; then
        sudo cp -fR /opt/R/$R_VERSION/syslib-bak/ /Library/Frameworks/R.framework/Versions/$TARGET_R_CUT_ARCH/Resources/library
      fi

      sudo rm -rf /Library/Frameworks/R.framework/Versions/syslib-bak
    fi

    exit 0
  fi
}

function install() {

  if [[ $(uname) == "Linux" ]]; then

    if [[ $(lsb_release -si) == "Ubuntu" ]]; then

      if [[ $(lsb_release -sr) == "18.04" || $(lsb_release -sr) == "20.04" ]]; then

        codename=$(lsb_release -sr)

        echo -e "→ Downloading \033[36mhttps://cdn.rstudio.com/r/ubuntu-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb\033[0m"
        wget -q "https://cdn.rstudio.com/r/ubuntu-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb"
        sudo dpkg -i r-${R_VERSION}_1_amd64.deb >/dev/null
        rm r-${R_VERSION}_1_amd64.deb
        sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
        sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript

        exit 0
      else

        install_from_source

      fi

    elif

      [[ $(lsb_release -si) == "Debian" ]]
    then

      codename=$(lsb_release -sr)

      echo -e "→ Downloading \033[36mhttps://cdn.rstudio.com/r/debian-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb\033[0m"
      wget -q "https://cdn.rstudio.com/r/ubuntu-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb"
      sudo dpkg -i r-${R_VERSION}_1_amd64.deb >/dev/null
      rm r-${R_VERSION}_1_amd64.deb
      sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
      sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript

      exit 0

    elif [[ $(lsb_release -si) == "CentOS" ]]; then

      codename=$(lsb_release -sr | cut -c 1)

      echo -e "→ Downloading \033[36mhttps://cdn.rstudio.com/r/centos-${codename//./}/pkgs/R-${R_VERSION}-1-1.x86_64.rpm\033[0m"
      wget -q "https://cdn.rstudio.com/r/centos-${codename//./}/pkgs/R-${R_VERSION}-1-1.x86_64.rpm"
      sudo yum -y install R-${R_VERSION}-1-1.x86_64.rpm >/dev/null
      rm R-${R_VERSION}-1-1.x86_64.rpm
      sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
      sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript

      exit 0

    else

      install_from_source

    fi

  fi

  if [[ $ARG_ARCH == "x86_64" ]]; then
    echo -e "→ Downloading x86_64 installer because \033[36m--arch x86_64\033[0m was set."
  fi

  if [[ $arm_avail != 1 && $ARG_ARCH != "x86_64" ]]; then
    echo -e "→ No arm installer available for this R version. Downloading \033[36mx86_64\033[0m version instead."
  fi

  # this means the request R version was smaller than 3.6.3
  if [[ $R3x == -1 ]]; then

    # prevent users from reinstalling an R version that already exists
    if [[ $R_VERSION != "devel" && $(test -d /opt/R/$R_VERSION/ && echo "true" || echo "false") == "true" ]]; then
      echo -e "R $R_VERSION is already installed - you only need to call \033[36mrcli switch $R_VERSION\033[0m to use it."
      exit 0
    fi

    echo -e "→ Downloading \033[36mhttps://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg\033[0m"
    curl -s https://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg

    R_CUT=$(echo $R_VERSION | cut -c 1-3)
    sudo rm -rf /Library/Frameworks/R.framework/Versions
    sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target / >/dev/null
    sudo mkdir -p /opt/R/$R_VERSION/
    sudo cp -fR /Library/Frameworks/R.framework/Versions/$R_CUT /opt/R/$R_VERSION/ 2>/dev/null
    sudo cp -fR /Library/Frameworks/R.framework/Versions/Current /opt/R/$R_VERSION/ 2>/dev/null

    rm /tmp/R-${R_VERSION}.pkg

  elif [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then

    # prevent users from reinstalling an R version that already exists
    if [[ $R_VERSION != "devel" && $(test -d /opt/R/$R_VERSION-arm64/ && echo "true" || echo "false") == "true" ]]; then
      echo -e "R $R_VERSION is already installed - you only need to call \033[36mrcli switch $R_VERSION\033[0m to use it."
      exit 0
    fi

    # if R is not installed at all yet, create frameworks dir
    if [[ $(test -d /Library/Frameworks/R.framework && echo "true" || echo "false") == "false" ]]; then
      sudo mkdir -p /Library/Frameworks/R.framework
    fi

    currentR=$(echo $(R --version) | cut -c 11-15)
    currentArch=$(R -s -q -e "Sys.info()[['machine']]" | cut -c 6- | sed 's/.$//')
    SYSLIB=$(R -q -s -e "tail(.libPaths())" | cut -c 6- | sed 's/.$//')
    R_CUT=$(echo $R_VERSION | cut -c 1-3)

    ### first time users
    # checks if /opt/R/ contains any R installations
    firstTime=$(ls -l /opt/R | awk '/^d/ { print $9 }' | grep "^[0-9][^/]*$" | sed "s/^/- /")
    # checks if the user has installed any custom libraries into the system lib
    if [[ $currentR != $R_VERSION && ${#firstTime} == 0 && $(find $SYSLIB -maxdepth 1 -type d | wc -l | xargs) > 31 ]]; then
      echo -e "⚠️  ⚠️  ⚠️\nHey there! It seems you are using \033[36mrcli\033[0m for the first time and trying to install an R version different from the one you are currently running. This is a problem if you do not make use of a user library (which it seems like) and instead install all your packages into your system library (which is the unfortunate default on macOS, so don't worry about having done anything wrong). To prevent package loss, please first run \033[36mrcli install $currentR\033[0m so your existing packages are retained.\n"

      echo -e "\033[36mrcli\033[0m is able to account for this approach by copying things around - however R version switching might take a bit longer. Please consider using a user library for your personal packages. You can do so by calling \033[36mmkdir -p /Users/$(whoami)/Library/R/$R_CUT\033[0m (x86) or \033[36mmkdir -p /Users/$(whoami)/Library/R/arm64/$R_CUT\033[0m (arm64) from the terminal. Note that this needs to be done for every R minor version (e.g. 4.1, 4.0 and so forth) and architecture.\n"

      echo -e "This is a one-time message and you won't see it again after you have installed your current R version via \033[36mrcli\033[0m as suggested above."
      exit 0
    fi

    if [[ $R_VERSION == "devel" ]]; then
      echo -e "→ Downloading \033[36mhttps://mac.r-project.org/big-sur/R-devel/R-devel.pkg\033[0m"
      curl -s https://mac.r-project.org/big-sur/R-devel/R-devel.pkg -o /tmp/R-${R_VERSION}-arm64.pkg
    else
      echo -e "→ Downloading \033[36mhttps://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg\033[0m"
      curl -s https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg -o /tmp/R-${R_VERSION}-arm64.pkg
    fi

    # backup current system library if non exists yet
    # this ensure that new rcli users don't loose their packages if they only use a system library
    # only invoked if the requested R version is the same as the running version
    SYSLIB_EXISTS=$(test -d /opt/R/$R_VERSION-arm64 && echo "true" || echo "false")
    if [[ $SYSLIB_EXISTS == "false" && $currentR == $R_VERSION ]]; then
      echo -e "ℹ Backing up current system library (\033[36m${SYSLIB}\033[0m) as no existing installation of R \033[36m${R_VERSION}\033[0m installed via \033[36mrcli\033[0m was found. This is a one-time action."
      RESTORE_SYSLIB="true"
      sudo mkdir -p /opt/R/$R_VERSION-arm64/syslib-bak
      sudo cp -fR $SYSLIB/* /opt/R/$R_VERSION-arm64/syslib-bak
    fi

    sudo rm -rf /Library/Frameworks/R.framework/Versions
    sudo installer -pkg /tmp/R-${R_VERSION}-arm64.pkg -target / >/dev/null
    rm /tmp/R-${R_VERSION}-arm64.pkg
    if [[ $R_VERSION == "devel" ]]; then
      R_VERSION=$(echo $(R -s -q -e 'paste(R.version[["major"]], R.version[["minor"]], sep = ".")') | cut -c 6-10)
      R_CUT=$(echo $R_VERSION | cut -c 1-3)
    fi
    sudo mkdir -p /opt/R/$R_VERSION-arm64/
    sudo cp -fR /Library/Frameworks/R.framework/Versions/$R_CUT-arm64 /opt/R/$R_VERSION-arm64/ 2>/dev/null
    sudo cp -fR /Library/Frameworks/R.framework/Versions/Current /opt/R/$R_VERSION-arm64/ 2>/dev/null

    if [[ $RESTORE_SYSLIB == "true" ]]; then
      sudo cp -fR /opt/R/$R_VERSION-arm64/syslib-bak/* $SYSLIB
    fi

  else
    # prevent users from reinstalling an R version that already exists
    if [[ $(test -d /opt/R/$R_VERSION/ && echo "true" || echo "false") == "true" ]]; then
      if [[ $R_VERSION != "devel" && $ARG_ARCH == "x86_64" ]]; then
        echo -e "R $R_VERSION is already installed - you only need to call \033[36mrcli switch $R_VERSION --arch x86_64\033[0m to use it."
        exit 0
      else
        echo -e "R $R_VERSION is already installed - you only need to call \033[36mrcli switch $R_VERSION\033[0m to use it."
        exit 0
      fi
    fi

    if [[ $R_VERSION == "devel" ]]; then
      echo -e "→ Downloading \033[36mhttps://mac.r-project.org/high-sierra/R-devel/R-devel.pkg\033[0m"
      curl -s https://mac.r-project.org/high-sierra/R-devel/R-devel.pkg -o /tmp/R-${R_VERSION}.pkg
    else
      echo -e "→ Downloading \033[36mhttps://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg\033[0m"
      curl -s https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg
    fi

    currentR=$(echo $(R --version) | cut -c 11-15)
    currentArch=$(R -s -q -e "Sys.info()[['machine']]" | cut -c 6- | sed 's/.$//')
    SYSLIB=$(R -q -s -e "tail(.libPaths())" | cut -c 6- | sed 's/.$//')

    # backup current system library if non exists yet
    # this ensure that new rcli users don't loose their packages if they only use a system library
    # only invoked if the requested R version is the same as the running version
    SYSLIB_EXISTS=$(test -d /opt/R/$R_VERSION-arm64 && echo "true" || echo "false")
    if [[ $SYSLIB_EXISTS == "false" && $currentR == $R_VERSION ]]; then
      echo -e "ℹ Backing up current system library (\033[36m${SYSLIB}\033[0m) as no existing installation of R \033[36m${R_VERSION}\033[0m installed via \033[36mrcli\033[0m was found. This is a one-time action."
      RESTORE_SYSLIB="true"
      sudo mkdir -p /opt/R/$R_VERSION/syslib-bak
      sudo cp -fR $SYSLIB/* /opt/R/$R_VERSION/syslib-bak
    fi

    R_CUT=$(echo $R_VERSION | cut -c 1-3)
    sudo rm -rf /Library/Frameworks/R.framework/Versions
    sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target / >/dev/null
    rm /tmp/R-${R_VERSION}.pkg
    if [[ $R_VERSION == "devel" ]]; then
      R_VERSION=$(echo $(R -s -q -e 'paste(R.version[["major"]], R.version[["minor"]], sep = ".")') | cut -c 6-10)
      R_CUT=$(echo $R_VERSION | cut -c 1-3)
    fi
    sudo mkdir -p /opt/R/$R_VERSION/
    sudo cp -fR /Library/Frameworks/R.framework/Versions/$R_CUT /opt/R/$R_VERSION/ 2>/dev/null
    sudo cp -fR /Library/Frameworks/R.framework/Versions/Current /opt/R/$R_VERSION/ 2>/dev/null

    if [[ $RESTORE_SYSLIB == "true" ]]; then
      sudo cp -fR /opt/R/$R_VERSION/syslib-bak/* $SYSLIB
    fi

  fi
}

function list() {

  if [[ $(uname) == "Linux" ]]; then

    if [[ $(lsb_release -si) == "Ubuntu" ]]; then

      echo -e "Installed R versions:"

      ls -l /opt/R | awk '/^d/ { print $9 }' | grep "^[0-9][^/]*$"

    fi

  elif [[ $(uname) == "Darwin" ]]; then

    echo -e "Installed R versions:"

    ls -l /opt/R | awk '/^d/ { print $9 }' | grep "^[0-9][^/]*$" | sed "s/^/- /"
  fi

}

# -*- tab-width: 2; encoding: utf-8 -*-

## @file version_compare
## Compare [semantic] versions in Bash, comparable to PHP's version_compare function.
# ------------------------------------------------------------------
## @author Mark Carver <mark.carver@me.com>
## @copyright MIT
## @version 1.0.0
## @see http://php.net/manual/en/function.version-compare.php

# Version compare
function version_compare() {
  # Default to a failed comparison result.
  local -i result=1

  # Ensure there are two versions to compare.
  [ $# -lt 2 ] || [ -z "${1}" ] || [ -z "${2}" ] && echo "${FUNCNAME[0]} requires a minimum of two arguments to compare versions." &>/dev/stderr && return ${result}

  # Determine the operation to perform, if any.
  local op="${3}"

  # Convert passed versions into values for comparison.
  local v1=$(version_compare_convert ${1})
  local v2=$(version_compare_convert ${2})

  # Immediately return when comparing version equality (which doesn't require sorting).
  if [ -z "${op}" ]; then
    [ "${v1}" == "${v2}" ] && echo 0 && return
  else
    if [ "${op}" == "!=" ] || [ "${op}" == "<>" ] || [ "${op}" == "ne" ]; then
      if [ "${v1}" != "${v2}" ]; then let result=0; fi
      return ${result}
    elif [ "${op}" == "=" ] || [ "${op}" == "==" ] || [ "${op}" == "eq" ]; then
      if [ "${v1}" == "${v2}" ]; then let result=0; fi
      return ${result}
    elif [ "${op}" == "le" ] || [ "${op}" == "<=" ] || [ "${op}" == "ge" ] || [ "${op}" == ">=" ] && [ "${v1}" == "${v2}" ]; then
      if [ "${v1}" == "${v2}" ]; then let result=0; fi
      return ${result}
    fi
  fi

  # If we get to this point, the versions should be different.
  # Immediately return if they're the same.
  [ "${v1}" == "${v2}" ] && return ${result}

  local sort='sort'

  # If only one version has a pre-release label, reverse sorting so
  # the version without one can take precedence.
  [[ "${v1}" == *"-"* ]] && [[ "${v2}" != *"-"* ]] || [[ "${v2}" == *"-"* ]] && [[ "${v1}" != *"-"* ]] && sort="${sort} -r"

  # Sort the versions.
  local -a sorted=($(printf "%s\n%s" "${v1}" "${v2}" | ${sort}))

  # No operator passed, indicate which direction the comparison leans.
  if [ -z "${op}" ]; then
    if [ "${v1}" == "${sorted[0]}" ]; then echo -1; else echo 1; fi
    return
  fi

  case "${op}" in
  "<" | "lt" | "<=" | "le") if [ "${v1}" == "${sorted[0]}" ]; then let result=0; fi ;;
  ">" | "gt" | ">=" | "ge") if [ "${v1}" == "${sorted[1]}" ]; then let result=0; fi ;;
  esac

  return ${result}
}

# Converts a version string to an integer that is used for comparison purposes.
function version_compare_convert() {
  local version="${@}"

  # Remove any build meta information as it should not be used per semver spec.
  version="${version%+*}"

  # Extract any pre-release label.
  local prerelease
  [[ "${version}" = *"-"* ]] && prerelease=${version##*-}
  [ -n "${prerelease}" ] && prerelease="-${prerelease}"

  version="${version%%-*}"

  # Separate version (minus pre-release label) into an array using periods as the separator.
  local OLDIFS=${IFS} && local IFS=. && version=(${version%-*}) && IFS=${OLDIFS}

  # Unfortunately, we must use sed to strip of leading zeros here.
  local major=$(echo ${version[0]:=0} | sed 's/^0*//')
  local minor=$(echo ${version[1]:=0} | sed 's/^0*//')
  local patch=$(echo ${version[2]:=0} | sed 's/^0*//')
  local build=$(echo ${version[3]:=0} | sed 's/^0*//')

  # Combine the version parts and pad everything with zeros, except major.
  printf "%s%04d%04d%04d%s\n" "${major}" "${minor}" "${patch}" "${build}" "${prerelease}"
}

function install_from_source() {

  echo -e "ℹ Installing \033[36mR $R_VERSION\033[0m from source as no binary is available for your system - this might take a while."

  R_BRANCH=$(echo $R_VERSION | cut -c 1)
  wget -q "https://cran.r-project.org/src/base/R-$R_BRANCH/R-$R_VERSION.tar.gz"

  tar -xf R-${R_VERSION}.tar.gz

  cd R-${R_VERSION}

  ## Set compiler flags and configure options
  R_PAPERSIZE=a4 \
    R_BATCHSAVE="--no-save --no-restore" \
    R_BROWSER=xdg-open \
    PAGER=/usr/bin/pager \
    PERL=/usr/bin/perl \
    R_UNZIPCMD=/usr/bin/unzip \
    R_ZIPCMD=/usr/bin/zip \
    R_PRINTCMD=/usr/bin/lpr \
    LIBnn=lib \
    AWK=/usr/bin/awk \
    CFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    CXXFLAGS="-g -O2 -fstack-protector-strong -Wformat -Werror=format-security -Wdate-time -D_FORTIFY_SOURCE=2 -g" \
    ./configure --enable-R-shlib \
    --enable-memory-profiling \
    --with-readline \
    --with-blas \
    --with-tcltk \
    --disable-nls \
    --with-recommended-packages \
    --with-pcre1 \
    --prefix=/opt/R/$R_VERSION/ \
    >/dev/null

  ## Build and install
  nice make -s "-j$(nproc)"

  sudo make -s install

  sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
  sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/bin/R
  sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript
  sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/bin/Rscript

  cd ../
  rm R-${R_VERSION}.tar.gz

  exit 0
}

function rcli() {

  ### EXAMPLES
  # shc -f rcli.sh && mv rcli.sh.x /opt/homebrew/bin/rcli && chmod +x /opt/homebrew/bin/rcli && rcli install 4.1.1 --arch x86_64

  # from https://stackoverflow.com/a/61055114/4185785
  parseArguments "${@}"

  R_VERSION=$2
  arch=$(uname -m)

  if [[ $1 == "install" ]]; then
    arm_avail=$(version_compare $R_VERSION 4.0.6)
    R3x="$(version_compare $R_VERSION 3.6.4)"
    install
    exit 0

  elif [[ $1 == "switch" ]]; then
    arm_avail=$(version_compare $R_VERSION 4.0.6)
    R3x="$(version_compare $R_VERSION 3.6.4)"
    switch
    exit 0

  elif [[ $1 == "list" ]]; then
    list
    exit 0

  else
    showInfo
    exit 0

  fi

}

[ $# -gt 0 ] && rcli ${@}
