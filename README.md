
## Create binary

```
shc -f rcli.sh && mv rcli.sh.x /opt/homebrew/bin/rcli && chmod +x /opt/homebrew/bin/rcli
```

## Homebrew

```sh
VERSION=v0.1.0
shc -f rcli.sh && mv rcli.sh.x rcli
tar cf bin/rcli-$VERSION.tar.gz rcli
rm rcli
sha256=$(shasum -a256 bin/rcli-$VERSION.tar.gz | cut -d ' ' -f 1)
gsed -i "5 s/.*/  sha256 \"$sha256\"/" brew/rcli.rb
cp brew/rcli.rb /opt/homebrew/Library/Taps/homebrew/homebrew-core/Formula/rcli.rb
brew reinstall --build-from-source rcli
```
