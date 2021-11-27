function switch() {
	# only branch specific switching is possible - we need to strip and write a warning
	if [[ ${#R_VERSION} == 5 ]]; then
		R_CUT=$(echo $R_VERSION | cut -c 1-3)
		echo -e "Only minor-version switching is possible, e.g. between versions 4.0 and 4.1.\nStripping the patch version from the supplied version '$R_VERSION' to '$R_CUT'.\nTo suppress this warning, omit the patch version."
		ARG_1=$R_CUT
	fi

	if [[ $ARG_ARCH == "x86_64" ]]; then
		echo "-> Switching to x86_64 R installation because --arch x86_64 was set."
	fi
	if [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then
		ln -sfn $ARG_1-arm64 /Library/Frameworks/R.framework/Versions/Current
	else
		ln -sfn $ARG_1 /Library/Frameworks/R.framework/Versions/Current
	fi
}
