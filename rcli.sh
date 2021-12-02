#!/bin/bash

if [[ $1 == "" ]]; then
  showInfo() {
    # `cat << EOF` This means that cat should stop reading when EOF is detected
    cat <<EOF
Usage: rcli [-h] [-v] [subcommand] <R version> [--arch ARCHITECTURE]

Available commands:
    install     Install an R version
    switch      Switch between installed R versions

EOF
    # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
  }

  showInfo
  exit 0

elif [[ $1 == "--version" || $1 == "-v" ]]; then
  echo "0.1.0"
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

EOF
    # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
  }

  showHelp
  exit 0
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

showInfo() {
  # `cat << EOF` This means that cat should stop reading when EOF is detected
  cat <<EOF
Usage: rcli [-h] [-v] [subcommand] <R version> [--arch ARCHITECTURE]

Available commands:
    install     Install an R version
    switch      Switch between installed R versions

EOF
  # EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
}

function switch() {

  if [[ $(uname) == "Linux" ]]; then

    if [[ $(lsb_release -si) == "Ubuntu" ]]; then

      exists=$(test -f /opt/R/$R_VERSION/bin/R && echo "true" || echo "false")

      if [[ $exists == "false" ]]; then
        echo -e "R version $R_VERSION does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION\033[0m."
        exit 0
      fi

      sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
      sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript

      exit 0
    fi
  fi

  R_CUT=$(echo $R_VERSION | cut -c 1-3)

  if [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then

    exists=$(test -f /opt/R/$R_VERSION-arm64/Library/Frameworks/R.framework/R && echo "true" || echo "false")
    if [[ $exists == "false" ]]; then
      echo -e "R $R_VERSION does not seem to be installed. Please install it via \033[36mrcli install $R_VERSION\033[0m."
      exit 0
    fi

    sudo rm -rf /Library/Frameworks/R.framework/Versions/*
    sudo cp -fR /opt/R/$R_VERSION-arm64/* /Library/Frameworks/R.framework/Versions 2>/dev/null
    sudo cp -fR /opt/R/$R_VERSION/$R_CUT-arm64/Resources /Library/Frameworks/R.framework/ 2>/dev/null

  else

    exists=$(test -f /opt/R/$R_VERSION/Library/Frameworks/R.framework/R && echo "true" || echo "false")
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

    sudo rm -rf /Library/Frameworks/R.framework/Versions/*
    sudo cp -fR /opt/R/$R_VERSION/* /Library/Frameworks/R.framework/Versions 2>/dev/null
    sudo cp -fR /opt/R/$R_VERSION/$R_CUT/Resources /Library/Frameworks/R.framework 2>/dev/null
  fi
}

function install() {

  if [[ $(uname) == "Linux" ]]; then

    if [[ $(lsb_release -si) == "Ubuntu" ]]; then

      codename=$(lsb_release -sr)
      sudo apt-get -qq -y install gfortran gfortran-9 icu-devtools liblapack3 libpcre2-32-0 libpcre2-posix2 libbz2-dev libblas-dev libicu-dev liblapack-dev liblzma-dev libpcre2-dev libtcl8.6 libtk8.6 libblas3 libgfortran-9-dev libgfortran5 libpcre3-dev libpcre16-3 libpcrecpp0v5 libpcre32-3 >/dev/null
      echo -e "→ Downloading \033[36mhttps://cdn.rstudio.com/r/ubuntu-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb\033[0m"
      wget -q "https://cdn.rstudio.com/r/ubuntu-${codename//./}/pkgs/r-${R_VERSION}_1_amd64.deb"
      sudo dpkg -i r-${R_VERSION}_1_amd64.deb >/dev/null
      rm r-${R_VERSION}_1_amd64.deb
      sudo ln -sf /opt/R/$R_VERSION/bin/R /usr/local/bin/R
      sudo ln -sf /opt/R/$R_VERSION/bin/Rscript /usr/local/bin/Rscript

      exit 0
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
    echo -e "→ Downloading \033[36mhttps://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg\033[0m"

    curl -s https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg -o /tmp/R-${R_VERSION}-arm64.pkg

    R_CUT=$(echo $R_VERSION | cut -c 1-3)
    sudo rm -rf /Library/Frameworks/R.framework/Versions
    sudo installer -pkg /tmp/R-${R_VERSION}-arm64.pkg -target / >/dev/null
    sudo mkdir -p /opt/R/$R_VERSION-arm64/
    sudo cp -fR /Library/Frameworks/R.framework/Versions/$R_CUT-arm64 /opt/R/$R_VERSION-arm64/ 2>/dev/null
    sudo cp -fR /Library/Frameworks/R.framework/Versions/Current /opt/R/$R_VERSION-arm64/ 2>/dev/null

    rm /tmp/R-${R_VERSION}-arm64.pkg
  else
    echo -e "→ Downloading \033[36mhttps://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg\033[0m"

    curl -s https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg

    R_CUT=$(echo $R_VERSION | cut -c 1-3)
    sudo rm -rf /Library/Frameworks/R.framework/Versions
    sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target / >/dev/null
    sudo mkdir -p /opt/R/$R_VERSION/
    sudo cp -fR /Library/Frameworks/R.framework/Versions/$R_CUT /opt/R/$R_VERSION/ 2>/dev/null
    sudo cp -fR /Library/Frameworks/R.framework/Versions/Current /opt/R/$R_VERSION/ 2>/dev/null

    rm /tmp/R-${R_VERSION}.pkg
  fi
}

function list() {

  if [[ $(uname) == "Linux" ]]; then

    if [[ $(lsb_release -si) == "Ubuntu" ]]; then

      echo -e "Installed R versions:\n"

      # ls -l /opt/R | grep '^d' | awk '{ print $9 }' | grep "^[0-9][^/]*$"
      ls -l /opt/R | awk '/^d/ { print $9 }' | grep "^[0-9][^/]*$"

    fi

  elif [[ $(uname) == "Darwin" ]]; then

    echo -e "Installed R versions:"

    # FIXME: check if grep is installed by default on macos
    # ls -l /opt/R | grep '^d' | awk '{ print $9 }' | grep "^[0-9][^/]*$"
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
