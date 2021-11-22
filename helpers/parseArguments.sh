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
  ARGUMENT="${1^^}"           # Capitalize.
  ARGUMENT="${ARGUMENT/--/}"  # Remove "--".
  ARGUMENT="${ARGUMENT//-/_}" # Replace "-" with "_".
  echo "${ARGUMENT}"
}
