#!/bin/bash -e

FAPT_ROOT=${HOME}/.fapt/fake

echo "starting to install $@"

# so long as we aren't using the cache list to configure by,
# there's no reason to clear it
#echo "cleaning the cache"
#apt-get -c ${FAPT_ROOT}/etc/apt/apt.conf clean

echo "downloading"
apt-get -c ${FAPT_ROOT}/etc/apt/apt.conf -d install $@
echo "unpacking"
fakeroot -- fakechroot --  /usr/bin/dpkg --unpack --auto-deconfigure  \
    --force-overwrite  \
    --root=${FAPT_ROOT}  \
    --force-not-root  \
    --log=${FAPT_ROOT}/var/log/dpkg.log  \
    ${FAPT_ROOT}/var/cache/apt/archives/*.deb

echo "configuring"

# this seems to fail on libc-bin, for some reason
fakeroot fakechroot chroot ${FAPT_ROOT} dpkg --configure --pending || true

# again, in case something (lookin' at you, libc-bin) was left dangling
fakeroot fakechroot chroot ${FAPT_ROOT} dpkg --configure --pending

#CONF_PKGS=$(fakeroot -- fakechroot --  /usr/bin/apt-get -c ${FAPT_ROOT}/etc/apt/apt.conf -s install $@ | grep Conf | cut -f 2 -d " ")

#fakeroot -- fakechroot --  /usr/bin/dpkg --configure  \
#    --force-overwrite  \
#    --root=${FAPT_ROOT}  \
#    --force-not-root  \
#    --log=${FAPT_ROOT}/var/log/dpkg.log  \
#    $CONF_PKGS


