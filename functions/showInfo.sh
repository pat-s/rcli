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
