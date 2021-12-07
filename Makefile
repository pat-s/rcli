VERSION := $(shell echo "0.1.0")

.PHONY: release
release:
	shc -f rcli.sh && mv rcli.sh.x rcli
	tar cf bin/rcli-$(VERSION)-alpha.tar.gz rcli
	rm rcli
	gsed -i "5 s/.*/  sha256 \"$(shasum -a256 bin/rcli-${VERSION}.tar.gz | cut -d ' ' -f 1)\"/" ~/git/homebrew-rcli/Formula/rcli.rb
	gsed -i "4 s/.*/  url \"https:\/\/github.com\/pat-s\/rcli\/archive\/refs\/tags\/$(VERSION)\.tar\.gz\"/" ~/git/homebrew-rcli/Formula/rcli.rb
	cd /Users/pjs/git/homebrew-rcli; git add Formula/rcli.rb
	# git commit -m "release v$VERSION"

test-mac:
	shc -f rcli.sh && mv rcli.sh.x rcli
	tar cf bin/rcli-$(VERSION).tar.gz rcli
	rm rcli
	gsed -i "5 s/.*/  sha256 \"$(shasum -a256 bin/rcli-${VERSION}.tar.gz | cut -d ' ' -f 1)\"/" ~/git/homebrew-rcli/Formula/rcli.rb
	gsed -i "4 s/.*/  url \"file\:\/\/\/Users\/pjs\/git\/rcli\/bin\/rcli-$(VERSION)\.tar\.gz\"/" ~/git/homebrew-rcli/Formula/rcli.rb
	cp ~/git/homebrew-rcli/Formula/rcli.rb /opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/rcli.rb
	brew reinstall --build-from-source --force rcli
