showHelp() {
	# `cat << EOF` This means that cat should stop reading when EOF is detected
	cat <<EOF
Usage:
- rcli [-h] [-v] install <R version> [--arch ARCHITECTURE]
- rcli [-h] [-v] switch  <R version> [--arch ARCHITECTURE]

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
