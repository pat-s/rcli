function install() {
	if [[ $ARG_ARCH == "x86_64" ]]; then
		echo -e "Downloading x86_64 installer because \033[36m --arch x86_64 \033[0m was set."
	fi

	if [[ $arm_avail != 1 && $ARG_ARCH != "x86_64" ]]; then
		echo -e "No arm installer available for this R version. Downloading \033[36m x86_64 \033[0m version instead."
	fi

	# this means the request R version was smaller than 3.6.3
	if [[ $R3x == -1 ]]; then

		echo -e "→ Downloading \033[36m https://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg \033[0m"
		curl -s https://cran.r-project.org/bin/macosx/el-capitan/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg
		# this preserves the previous installation
		sudo pkgutil --forget org.r-project.R.el-capitan.fw.pkg
		sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target / -dumplog /Volumes/Server/Share/installer.log
		rm /tmp/R-${R_VERSION}.pkg

	elif [[ ($arch == "arm64" && $arm_avail == 1 && $ARG_ARCH != "x86_64") ]]; then
		echo -e "→ Downloading \033[36m https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg \033[0m"
		curl -s https://cran.r-project.org/bin/macosx/big-sur-arm64/base/R-${R_VERSION}-arm64.pkg -o /tmp/R-${R_VERSION}-arm64.pkg
		# this preserves the previous installation
		sudo pkgutil --forget org.R-project.arm64.R.fw.pkg
		sudo installer -pkg /tmp/R-${R_VERSION}-arm64.pkg -target / -dumplog /Volumes/Server/Share/installer.log
		rm /tmp/R-${R_VERSION}-arm64.pkg
	else
		echo -e "→ Downloading \033[36m https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg \033[0m"
		curl -s https://cran.r-project.org/bin/macosx/base/R-${R_VERSION}.pkg -o /tmp/R-${R_VERSION}.pkg
		# this preserves the previous installation
		sudo pkgutil --forget org.R-project.R.fw.pkg
		sudo installer -pkg /tmp/R-${R_VERSION}.pkg -target / -dumplog /Volumes/Server/Share/installer.log
		rm /tmp/R-${R_VERSION}.pkg
	fi
}
