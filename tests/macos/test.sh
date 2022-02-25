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

echo -e "#### Switching devel -> 4.0.5"
./rcli.sh switch 4.0.5 >>/tmp/test-results/out.txt
R -q -s -e "library('cli')" >>/tmp/test-results/out.txt

echo -e "#### Remove R 4.1.2"
./rcli.sh remove 4.1.2 >>/tmp/test-results/out.txt

echo -e "#### List installed R versions"
./rcli.sh ls >>/tmp/test-results/out.txt
