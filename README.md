# kescher-archpp

This is a custom repo for [Pine64-Arch](https://github.com/dreemurrs-embedded/Pine64-Arch).
It contains various software that is useful for this particular distribution of Arch Linux ARM, but currently not packaged in the "official" repos.

# Add to your installation

## Trust the key for package and database signatures

### Option 1
Download the [kescher-keyring package](https://archpp.mirror.kescher.at/aarch64/kescher-keyring-20210613-1-any.pkg.tar.zst), verify [its signature](https://archpp.mirror.kescher.at/aarch64/kescher-keyring-20210613-1-any.pkg.tar.zst.sig). It should match the key with ID `9D3E8E1AD5FE25C86007E39CDCD2605CBA2DD2DF`. Install the package using `pacman -U <path to keyring package file>`.

### Option 2
Assuming you have working gpg keyserver options in `/etc/pacman.d/gnupg/gpg.conf`, you may also be able to do the following:

```
pacman-key --recv-keys 9D3E8E1AD5FE25C86007E39CDCD2605CBA2DD2DF
pacman-key --finger 9D3E8E1AD5FE25C86007E39CDCD2605CBA2DD2DF
pacman-key --lsign-key 9D3E8E1AD5FE25C86007E39CDCD2605CBA2DD2DF
```

## Add to pacman.conf

Add the following lines to your `/etc/pacman.conf`:

```
[kescher-archpp]
Server = https://archpp.mirror.kescher.at/$arch
```

## Update your databases
Simply run `pacman -Syu` or `yay`, depending on the package manager you use.

