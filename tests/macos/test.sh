mkdir -p /tmp/test-results && touch /tmp/test-results/out.txt

./rcli.sh install
./rcli.sh install 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt
./rcli.sh install 4.1.2 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt
./rcli.sh install 4.1.2 --force && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt
./rcli.sh install 4.0.5 && R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

echo -e "#### Switching 4.0.5 -> 4.1.2"
./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "install.packages('gam', repos = 'https://cran.us.r-project.org', quiet = TRUE)" >/dev/null

echo -e "#### Switching 4.1.2 -> 4.0.5"
./rcli.sh switch 4.0.5 --debug >>/tmp/test-results/out.txt
R -q -s -e "install.packages('cli', repos = 'https://cran.us.r-project.org', quiet = TRUE)" >/dev/null

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

echo -e "#### Remove R 4.1.2"
./rcli.sh remove 4.1.2 >>/tmp/test-results/out.txt

echo -e "#### Install rel"
./rcli.sh install rel >>/tmp/test-results/out.txt

echo -e "#### Remove R devel"
./rcli.sh remove dev >>/tmp/test-results/out.txt

echo -e "#### Remove R 4.1.2 again (and expect error)"
./rcli.sh remove 4.1.2 >>/tmp/test-results/out.txt

echo -e "#### List installed R versions"
./rcli.sh ls >>/tmp/test-results/out.txt

if [[ $(diff tests/macos/test-out-x86.txt /tmp/test-results/out.txt) == "" ]]; then exit 0; else diff --unified tests/macos/test-out-x86.txt /tmp/test-results/out.txt && exit 1; fi
