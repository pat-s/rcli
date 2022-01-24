
VERSION=0.5.1

tar cf rcli-$VERSION.tar rcli.sh
gzip rcli-$VERSION.tar
mkdir rcli-$VERSION
cp rcli.sh rcli-$VERSION
cd rcli-$VERSION
rm -rf debian
dh_make -f ../rcli-$VERSION.tar.gz -s --copyright mit -y
sed -i "2 s/.*/Section: devel/g" debian/control
sed -i "7 s#.*#Homepage: https://github.com/pat-s/rcli#g" debian/control
sed -i "9 s#.*#Vcs-Git: https://github.com/pat-s/rcli.git#g" debian/control
sed -i "12 s#.*#Architecture: all#g" debian/control
sed -i "13 s#.*#Depends: dpkg#g" debian/control
sed -i "14 s#.*#Description: Command line tool to install and switch between R versions#g" debian/control
sed -i "15 s#.*##g" debian/control

#grep -v makefile debian/rules > debian/rules.new
#mv debian/rules.new debian/rules
cp ../CHANGELOG debian/changelog

mv rcli.sh rcli
echo rcli usr/bin > debian/install
rm debian/*.ex
debuild -S -kpatrick.schratz@gmail.com
#sudo dpkg -i ../rcli_$VERSION-1_all.deb

dput ppa:pat-s/rcli -f  ../rcli_$VERSION-1_source.changes

rm ../rcli_$VERSION-1*
rm ../rcli_$VERSION.*
rm ../rcli-$VERSION*

#sudo rm -rf rcli-$VERSION
cd ..
rm -rf rcli-$VERSION



