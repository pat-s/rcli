


tar cf rcli-0.5.1.tar rcli.sh
gzip rcli-0.5.1.tar
mkdir rcli-0.5.1
cp rcli.sh rcli-0.5.1
cd rcli-0.5.1
rm -rf debian
dh_make -f ../rcli-0.5.1.tar.gz -s --copyright mit -y
sed -i "2 s/.*/Section: devel/g" debian/control
sed -i "7 s/.*/Homepage: https://github.com/pat-s/rcli/g" debian/control
sed -i "9 s#.*#Vcs-Git: https://github.com/pat-s/rcli.git#g" debian/control
sed -i "12 s#.*#Architecture: all#g" debian/control
sed -i "13 s#.*#Depends: dpkg#g" debian/control
sed -i "14 s#.*#Description: Command line tool to install and switch between R versions#g" debian/control
sed -i "15 s#.*##g" debian/control

grep -v makefile debian/rules > debian/rules.new
mv debian/rules.new debian/rules
cp ../CHANGELOG debian/changelog

mv rcli.sh rcli
echo rcli usr/bin > debian/install
rm debian/*.ex
sudo dh binary-indep
sudo dpkg -i ../rcli_0.5.1-1_all.deb

dput ppa:pat-s/rcli
rm ../rcli_0.5.1-1.*
rm ../rcli_0.5.1.tar.gz
sudo rm -rf rcli-0.5.1
cd ..







bzr whoami "Patrick Schratz <patrick.schratz@gmail.com>"
bzr dh-make rcli 0.5.1 rcli.tar.gz




# Configure your paths and filenames
export DEBFULLNAME="Patrick Schratz"
SOURCEBINPATH=~/git/rcli
SOURCEBIN=rcli.sh
DEBFOLDER=~/git/rcli
DEBVERSION=0.5.1

DEBFOLDERNAME=$DEBFOLDER-$DEBVERSION

# Create your scripts source dir
mkdir $DEBFOLDERNAME

# Copy your script to the source dir
cp $SOURCEBINPATH/$SOURCEBIN $DEBFOLDERNAME
cd $DEBFOLDERNAME

# Create the packaging skeleton (debian/*)
dh_make --indep --createorig -y -e patrick.schratz@gmail.com

# Remove make calls
grep -v makefile debian/rules >debian/rules.new
mv debian/rules.new debian/rules

# debian/install must contain the list of scripts to install
# as well as the target directory
echo $SOURCEBIN usr/bin >debian/install

# Remove the example files
rm debian/*.ex

# Build the package.
# You  will get a lot of warnings and ../somescripts_0.1-1_i386.deb
debuild
