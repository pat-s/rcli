set -e
set -x
set -o pipefail

mkdir -p /tmp/test-results

./rcli.sh install >>/tmp/test-results/out.txt

./rcli.sh install 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh install 3.6.3 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh switch 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh install 4.0.5 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >>/tmp/test-results/out.txt

./rcli.sh remove 4.1.2 >>/tmp/test-results/out.txt

./rcli.sh ls >>/tmp/test-results/out.txt

if [[ $(diff tests/ubuntu-20.04/test-out.txt /tmp/test-results/out.txt) == "" ]]; then exit 0; else exit 1; fi
