export RCLI_ASK_USER_LIB=false

if [[ $CI != "true" ]]; then

	# don't stop on errors
	set +e

	# start fresh
	sudo rm -rf /Library/Frameworks/R.framework

	# we need R to available
	brew install -q --cask r

	mkdir /tmp/r-bak
	mkdir /tmp/r-lib-bak

	sudo mv /opt/R /tmp/r-bak
	mv ~/Library/R /tmp/r-lib-bak

fi

mkdir -p /tmp/test-results && touch /tmp/test-results/out.txt

echo -e "#### Trigger 'please pass a version'"
./rcli.sh install >>/tmp/test-results/out.txt

echo -e "#### Install 4.1.2"
./rcli.sh install 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Trigger 'already installed'"
./rcli.sh install 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Force reinstall"
./rcli.sh install 4.1.2 --force && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Install 4.0.5"
./rcli.sh install 4.0.5 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Switching 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "install.packages('gam', repos = 'https://cran.us.r-project.org', quiet = TRUE, type = 'binary')" >/dev/null

echo -e "#### Switching 4.1.2 -> 4.0.5"
./rcli.sh switch 4.0.5 --debug >>/tmp/test-results/out.txt
R -q -s -e "install.packages('cli', repos = 'https://cran.us.r-project.org', quiet = TRUE, type = 'binary')" >/dev/null

echo -e "#### Switching 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 --debug >>/tmp/test-results/out.txt
R -q -s -e "library('gam')" >>/tmp/test-results/out.txt

echo -e "#### Installing R devel"
./rcli.sh install devel
R -q -s -e "substr(R.version.string, 1, 19)" >>/tmp/test-results/out.txt

echo -e "#### Switching devel -> 4.0.5"
./rcli.sh switch 4.0.5 >>/tmp/test-results/out.txt
R -q -s -e "library('cli')" >>/tmp/test-results/out.txt

echo -e "#### Switching 4.0.5 -> devel"
./rcli.sh switch dev >>/tmp/test-results/out.txt

# not saving in output as the value would change constantly
echo -e "#### Remove R 4.1.2"
./rcli.sh remove 4.1.2

echo -e "#### Remove R 4.1.2 again (and expect error)"
./rcli.sh remove 4.1.2 >>/tmp/test-results/out.txt

# not saving in output as the value would change constantly
echo -e "#### Remove R devel"
./rcli.sh remove dev

echo -e "#### List installed R versions"
./rcli.sh ls >>/tmp/test-results/out.txt

# not saving in output as the value would change constantly
echo -e "#### Install rel"
./rcli.sh install rel

# arm specific tests
if [[ $CI != "true" && $(arch) == "arm64" ]]; then

	if [[ $(diff tests/macos/test-out-all.txt /tmp/test-results/out.txt) == "" ]]; then exit 0; else diff --unified tests/macos/test-out-all.txt /tmp/test-results/out.txt && exit 1; fi

	# clean
	sudo rm -rf /opt/R

	# restore
	sudo mv /tmp/r-bak/* /opt/R
	mkdir ~/Library/R && mv /tmp/r-lib-bak/* ~/Library/R

	# clean
	sudo rm -rf /tmp/r-bak /tmp/r-lib-bak
	rm /tmp/test-results/out.txt

	brew remove --cask r

else

	if [[ $(diff tests/macos/test-out-x86.txt /tmp/test-results/out.txt) == "" ]]; then exit 0; else diff --unified tests/macos/test-out-x86.txt /tmp/test-results/out.txt && exit 1; fi

fi

unset RCLI_ASK_USER_LIB
