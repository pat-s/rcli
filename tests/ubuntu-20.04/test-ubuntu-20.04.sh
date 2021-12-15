mkdir -p /tmp/test-results
chmod +x /usr/local/bin/./rcli.sh
./rcli.sh install 4.1.2 >>/tmp/test-results/out
R -q -s -e "R.version.string" >/tmp/test-results/out
./rcli.sh install 3.6.3 >>/tmp/test-results/out
R -q -s -e "R.version.string" >>/tmp/test-results/out
./rcli.sh switch 4.1.2 >>/tmp/test-results/out
R -q -s -e "R.version.string" >>/tmp/test-results/out
if [[ $(diff tests/ubuntu-20.04/test-out.txt /tmp/test-results/out) == "" ]]; then exit 0; else exit 1; fi
