mkdir -p /tmp/test-results

rcli install 4.1.2 >>/tmp/test-results/out
R -q -s -e "R.version.string" >/tmp/test-results/out >>/tmp/test-results/out
if [[ $(diff tests/ubuntu-21.10/test-out.txt /tmp/test-results/out) == "" ]]; then exit 0; else exit 1; fi
