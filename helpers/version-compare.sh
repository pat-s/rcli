#!/opt/homebrew/bin/bash
# -*- tab-width: 2; encoding: utf-8 -*-

## @file version_compare
## Compare [semantic] versions in Bash, comparable to PHP's version_compare function.
# ------------------------------------------------------------------
## @author Mark Carver <mark.carver@me.com>
## @copyright MIT
## @version 1.0.0
## @see http://php.net/manual/en/function.version-compare.php

APP_NAME=$(basename ${0})
APP_VERSION="1.0.0"

# Version compare
function version_compare () {
  # Default to a failed comparison result.
  local -i result=1;

  # Ensure there are two versions to compare.
  [ $# -lt 2 ] || [ -z "${1}" ] || [ -z "${2}" ] && echo "${FUNCNAME[0]} requires a minimum of two arguments to compare versions." &>/dev/stderr && return ${result}

  # Determine the operation to perform, if any.
  local op="${3}"

  # Convert passed versions into values for comparison.
  local v1=$(version_compare_convert ${1})
  local v2=$(version_compare_convert ${2})

  # Immediately return when comparing version equality (which doesn't require sorting).
  if [ -z "${op}" ]; then
    [ "${v1}" == "${v2}" ] && echo 0 && return;
  else
    if [ "${op}" == "!=" ] || [ "${op}" == "<>" ] || [ "${op}" == "ne" ]; then
      if [ "${v1}" != "${v2}" ]; then let result=0; fi;
      return ${result};
    elif [ "${op}" == "=" ] || [ "${op}" == "==" ] || [ "${op}" == "eq" ]; then
      if [ "${v1}" == "${v2}" ]; then let result=0; fi;
      return ${result};
    elif [ "${op}" == "le" ] || [ "${op}" == "<=" ] || [ "${op}" == "ge" ] || [ "${op}" == ">=" ] && [ "${v1}" == "${v2}" ]; then
      if [ "${v1}" == "${v2}" ]; then let result=0; fi;
      return ${result};
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
    "<" | "lt" | "<=" | "le") if [ "${v1}" == "${sorted[0]}" ]; then let result=0; fi;;
    ">" | "gt" | ">=" | "ge") if [ "${v1}" == "${sorted[1]}" ]; then let result=0; fi;;
  esac

  return ${result}
}

# Converts a version string to an integer that is used for comparison purposes.
function version_compare_convert () {
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

# Color Support
# See: http://unix.stackexchange.com/a/10065
if test -t 1; then
  ncolors=$(tput colors)
  if test -n "$ncolors" && test $ncolors -ge 8; then
    bold="$(tput bold)" && underline="$(tput smul)" && standout="$(tput smso)" && normal="$(tput sgr0)"
    black="$(tput setaf 0)" && red="$(tput setaf 1)" && green="$(tput setaf 2)" && yellow="$(tput setaf 3)"
    blue="$(tput setaf 4)" && magenta="$(tput setaf 5)" && cyan="$(tput setaf 6)" && white="$(tput setaf 7)"
  fi
fi

function version_compare_usage {
  echo "${bold}${APP_NAME} (${APP_VERSION})${normal}"
  echo "Compare [semantic] versions in Bash, comparable to PHP's version_compare function."
  echo
  echo "${bold}Usage:${normal}"
  echo "    ${APP_NAME} [-hV] ${cyan}<version1> <version2>${normal} [${cyan}<operator>${normal}]"
  echo
  echo "${bold}Required arguments:${normal}"
  echo "    - ${cyan}<version1>${normal}: First version number to compare."
  echo "    - ${cyan}<version2>${normal}: Second version number to compare."
  echo
  echo "${bold}Optional arguments:${normal}"
  echo "    - ${cyan}<operator>${normal}: When this argument is provided, it will test for a particular"
  echo "      relationship. This argument is case-sensitive, values should be lowercase."
  echo "      Possible operators are:"
  echo "          ${bold}=, ==, eq${normal}    (equal)"
  echo "          ${bold}>, gt${normal}        (greater than)"
  echo "          ${bold}>=, ge${normal}       (greater than or equal)"
  echo "          ${bold}<, lt${normal}        (less than)"
  echo "          ${bold}<=, le${normal}       (less than or equal)"
  echo "          ${bold}!=, <>, ne${normal}   (not equal)"
  echo
  echo "${bold}Return Value:${normal}"
  echo "    There are two distinct operation modes for ${APP_NAME}. It's solely based"
  echo "    on whether or not the ${cyan}<operator>${normal} argument was provided:"
  echo
  echo "    - When ${cyan}<operator>${normal} IS provided, ${APP_NAME} will return either a 0 or 1"
  echo "      exit code (no output printed to /dev/stdout) based on the result of the ${cyan}<operator>${normal}"
  echo "      relationship between the versions. This is particularly useful in cases where"
  echo "      testing versions can, historically, be quite cumbersome:"
  echo
  echo "          ${magenta}! ${APP_NAME} \${version1} \${version2} \">\" && echo \"You have not met the minimum version requirements.\" && exit 1${normal}"
  echo
  echo "      You can, of course, opt for the more traditional/verbose conditional"
  echo "      block in that suites your fancy:"
  echo
  echo "          ${magenta}${APP_NAME} \${version1} \${version2}"
  echo "          if [ \$? -gt 0 ]; then"
  echo "            echo \"You have not met the minimum version requirements.\""
  echo "            exit 1"
  echo "          fi${normal}"
  echo
  echo "    - When ${cyan}<operator>${normal} is NOT provided, ${APP_NAME} will output (print to /dev/stdout):"
  echo "          -1: ${cyan}<version1>${normal} is lower than ${cyan}<version2>${normal}"
  echo "           0: ${cyan}<version1>${normal} and ${cyan}<version2>${normal} are equal"
  echo "           1: ${cyan}<version2>${normal} is lower than ${cyan}<version1>${normal}"
  echo
  echo "      This mode is primarily only ever helpful when there is a need to determine the"
  echo "      relationship between two versions and provide logic for all three states:"
  echo
  echo "          ${magenta}ret=\$(${APP_NAME} \${version1} \${version2})"
  echo "          if [ \"\${ret}\" == \"-1\" ]; then"
  echo "            # Do some logic here."
  echo "          elif [ \"\${ret}\" == \"0\" ]; then"
  echo "            # Do some logic here."
  echo "          else"
  echo "            # Do some logic here."
  echo "          fi${normal}"
  echo
  echo "    While there are use cases for both modes, it's recommended that you provide an"
  echo "    ${cyan}<operator>${normal} argument to reduce any logic whenever possible."
  echo
  echo "${bold}Options:${normal}"
  echo "  ${bold}-h${normal}  Display this help and exit."
  echo "  ${bold}-V${normal}  Display version information and exit."
}

# Do not continue if sourced.
[[ ${0} != "$BASH_SOURCE" ]] && return

# Process options.
while getopts ":hV" opt; do
    case $opt in
      h) version_compare_usage && exit;;
      V) echo "${APP_VERSION}" && exit;;
      \?|*) echo "${red}${APP_NAME}: illegal option: -- ${OPTARG}${normal}" >&2 && echo && version_compare_usage && exit 64;;
    esac
done
shift $((OPTIND-1)) # Remove parsed options.

# Allow script to be invoked as a CLI "command" by proxying arguments to the internal function.
[ $# -gt 0 ] && version_compare ${@}
