mkdir -p /tmp/test-results

./rcli.sh install 4.1.2 >>/tmp/test-results/out.txt
R -q -s -e "R.version.string" >/tmp/test-results/out >>/tmp/test-results/out.txt
if [[ $(diff tests/fedora/test-out.txt /tmp/test-results/out) == "" ]]; then exit 0; else diff --unified tests/fedora/test-out.txt /tmp/test-results/out.txt && exit 1; fi
