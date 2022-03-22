set -e
set -x

mkdir /tmp/test-results

./rcli.sh install 4.1.1 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh install 3.6.3 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh switch 4.1.1 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh remove 3.6.3 >>/tmp/test-results/out.txt

./rcli.sh ls >>/tmp/test-results/out.txt

if [[ $(diff tests/rockylinux8/test-out.txt /tmp/test-results/out.txt) == "" ]]; then exit 0; else diff --unified tests/rockylinux8/test-out.txt /tmp/test-results/out.txt && exit 1; fi
