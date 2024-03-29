export RCLI_ASK_USER_LIB=false

if [[ $CI != "true" ]]; then

	# don't stop on errors
	set +e

	# start fresh
	sudo rm -rf /Library/Frameworks/R.framework

	curl -s https://cran.r-project.org/bin/macosx/base/R-4.0.5.pkg -o /tmp/R-4.0.5.pkg
	sudo installer -pkg /tmp/R-4.0.5.pkg -target / >/dev/null
	rm /tmp/R-4.0.5.pkg

	mkdir /tmp/r-bak >/dev/null
	mkdir /tmp/r-lib-bak >/dev/null

	if [[ -d /opt/R ]]; then
		sudo mv /opt/R /tmp/r-bak
	fi

	if [[ -d ~/Library/R ]]; then
		mv ~/Library/R /tmp/r-lib-bak
	fi

fi

mkdir -p /tmp/test-results
touch /tmp/test-results/out.txt

echo -e "#### Trigger 'please pass a version'"
./rcli.sh install >>/tmp/test-results/out.txt

echo -e "#### Install 4.1.2"
./rcli.sh install 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Install 4.1.2 with arm specifier"
./rcli.sh install 4.1.2-arm >>/tmp/test-results/out.txt

echo -e "#### Trigger 'already installed'"
./rcli.sh install 4.1.2 >>/tmp/test-results/out.txt

echo -e "#### Force reinstall"
./rcli.sh install 4.1.2 --force && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Install 4.0.5"
./rcli.sh install 4.0.5 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Switching 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "install.packages('gam', repos = 'https://cloud.r-project.org', quiet = TRUE, type = 'binary')" >/dev/null

echo -e "#### Switching 4.1.2 -> 4.0.5"
./rcli.sh switch 4.0.5 >>/tmp/test-results/out.txt
R -q -s -e "install.packages('cli', repos = 'https://cloud.r-project.org', quiet = TRUE, type = 'binary')" >/dev/null

echo -e "#### Switching 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "library('gam')" >>/tmp/test-results/out.txt

echo -e "#### Installing R devel"
./rcli.sh install devel >>/tmp/test-results/out.txt
if [[ $(./rcli.sh install devel) =~ "ERROR" ]]; then
	:
else
	R -q -s -e "substr(R.version.string, 1, 19)" >>/tmp/test-results/out.txt
	R -q -s -e "install.packages('cli', repos = 'https://cloud.r-project.org', quiet = TRUE)" >/dev/null
fi

echo -e "#### Switching devel or 4.1.2 -> 4.0.5"
./rcli.sh switch 4.0.5 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt
R -q -s -e "library('cli')" >>/tmp/test-results/out.txt
ls -ld /usr/local/bin/R
which R

if [[ $(./rcli.sh install devel) =~ "ERROR" ]]; then
	:
else
	echo -e "#### Switching 4.0.5 -> devel"
	./rcli.sh switch dev && R -q -s -e "R.version.string" | cut -c 1-20 >>/tmp/test-results/out.txt
	ls -ld /usr/local/bin/R
	which R
fi

echo -e "#### Switching devel or 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt
R_VERSION=$(R -q -s -e "R.version.string")
echo -e "#### Switching devel or 4.0.5 -> 4.1.2: $R_VERSION"
ls -ld /usr/local/bin/R
which R

# not saving in output as the value would change constantly
# sending output to /dev/null as the r-devel no-avail check would print to stdout otherwise
if [[ $(./rcli.sh install devel) =~ "ERROR" ]]; then
	:
else

	echo -e "#### Switching devel -> 4.1.2"
	./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt

	echo -e "#### Remove R devel"
	ls -ld /usr/local/bin/R
	./rcli.sh remove dev >>/tmp/test-results/out-no-track.txt
fi

echo -e "#### Remove R 4.0.5"
./rcli.sh remove 4.0.5 >>/tmp/test-results/out.txt
OUTPUT=$(R -q -s -e "R.version.string")
echo -e "#### Remove R 4.0.5: ${OUTPUT}"

echo -e "#### Remove R 4.0.5 again (and expect error)"
./rcli.sh remove 4.0.5 >>/tmp/test-results/out.txt
OUTPUT=$(R -q -s -e "R.version.string")
echo -e "#### Remove R 4.0.5 again (and expect error): ${OUTPUT}"

echo -e "#### List installed R versions"
./rcli.sh ls >>/tmp/test-results/out.txt
OUTPUT=$(R -q -s -e "R.version.string")
echo -e "#### List installed R versions: ${OUTPUT}"

# not saving in output as the value would change constantly
echo -e "#### Install rel"
./rcli.sh install rel
OUTPUT=$(R -q -s -e "R.version.string")
echo -e "#### Install rel: $OUTPUT"

# arm specific tests
if [[ $CI != "true" && $(arch) == "arm64" ]]; then

	# clean
	sudo rm -rf /opt/R

	# restore
	sudo mv /tmp/r-bak/* /opt/R

	if [[ -d /tmp/r-lib-bak ]]; then
		mkdir ~/Library/R
		mv /tmp/r-lib-bak/R/* ~/Library/R
	fi

	# clean
	sudo rm -rf /tmp/r-bak /tmp/r-lib-bak

	if [[ $(diff tests/macos/test-out-all.txt /tmp/test-results/out.txt) == "" ]]; then
		exit 0
	else
		mv /tmp/test-results/out.txt /tmp/test-results/test-fail-rcli.txt
		diff --unified tests/macos/test-out-x86.txt /tmp/test-results/test-fail-rcli.txt
		rm /tmp/test-results/out.txt
		echo -e "TESTS FAILED: Open artifact via code /tmp/test-results/test-fail-rcli.txt"
		exit 1
	fi

else

	# condition on whether installing r-devel failed or not
	if [[ $(./rcli.sh install devel) =~ "ERROR" ]]; then
		if [[ $(diff tests/macos/test-out-x86-no-devel.txt /tmp/test-results/out.txt) == "" ]]; then
			exit 0
		else
			mv /tmp/test-results/out.txt /tmp/test-results/test-fail-rcli.txt
			diff --unified tests/macos/test-out-x86-no-devel.txt /tmp/test-results/test-fail-rcli.txt
			exit 1
		fi
	else
		if [[ $(diff tests/macos/test-out-x86.txt /tmp/test-results/out.txt) == "" ]]; then
			exit 0
		else
			mv /tmp/test-results/out.txt /tmp/test-results/test-fail-rcli.txt
			diff --unified tests/macos/test-out-x86.txt /tmp/test-results/test-fail-rcli.txt
			exit 1
		fi
	fi

fi

unset RCLI_ASK_USER_LIB
