#!/bin/bash -e

echo "installing fapt..."

FAPT_ROOT=${HOME}/.fapt/fake
SCRIPT_DIR="$( cd "$( dirname "$BASH_SOURCE" )" && pwd )"


mkdir -p $FAPT_ROOT/bin
mkdir -p $FAPT_ROOT/tmp

curl -o $FAPT_ROOT/tmp/bootstrap_local_bash_env.sh https://github.com/gabrielgrant/bootstrap/raw/master/bootstrap_local_bash_env.sh
bash $FAPT_ROOT/tmp/bootstrap_local_bash_env.sh

if ! type -P fakechroot &>/dev/null; then
    echo "Installing fakechroot..."

    cd $FAPT_ROOT/tmp
    curl -O http://cloud.github.com/downloads/fakechroot/fakechroot/fakechroot-2.14.tar.gz
    tar -xzf fakechroot-2.14.tar.gz
    cd fakechroot-2.14
    ./configure --prefix=$FAPT_ROOT
    make
    make install
    cd ~/
fi

# allows chroot to start
ln -sf /bin/bash $FAPT_ROOT/bin/bash

# for others with shebang lines
ln -sf /bin/sh $FAPT_ROOT/bin/sh


# ensure at least the basic bin directories are on PATH

BASIC_PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
PATH=$PATH:$BASIC_PATH

# deduplicate (from http://chunchung.blogspot.com/2007/11/remove-duplicate-paths-from-path-in.html)
PATH=`awk -F: '{for(i=1;i<=NF;i++){if(!($i in a)){a[$i];printf s$i;s=":"}}}'<<<$PATH`

# give access to executables outside of chroot
#

REALROOT_PATH=`awk -F: '{for(i=1;i<=NF;i++){printf s"/realroot"$i;s=":"}}'<<<$PATH`
#PATH=$PATH:$BACKUP_PATH
ln -sf / $FAPT_ROOT/realroot || true

FAPT_PATH=`awk -v fapt_root=$FAPT_ROOT -F: '{for(i=1;i<=NF;i++){printf s fapt_root$i;s=":"}}'<<<$PATH`

# should do the same thing
# FAPT_PATH=`python -c "print ':'.join('$FAPT_ROOT'+p for p in '$PATH'.split(':')),"`

FAPT_LD_LIBRARY_PATH=`fakeroot $FAPT_ROOT/bin/fakechroot chroot $FAPT_ROOT /bin/bash -c '/realroot/bin/echo $LD_LIBRARY_PATH'`
#FAPT_LD_LIBARY_PATH=`python -c "print ':'.join(p.replace('$FAPT_ROOT', '') if p.startswith('$FAPT_ROOT') else '$FAPT_ROOT'+p for p in '$FAPT_LD_LIBRARY_PATH'.split(':')),"`


if [ "$(grep 'REALROOT_PATH' ~/.profile_extras)" ]; then
    echo "~/.profile_extras already contains REALROOT_PATH. Moving right along..."
else
    echo "
export FAPT_ROOT=${HOME}/.fapt/fake

# fapt paths
export PATH=$FAPT_PATH:\$PATH:$REALROOT_PATH

export REALROOT_PATH=$REALROOT_PATH


# fapt lib path
export LD_LIBRARY_PATH=$FAPT_LD_LIBRARY_PATH:\$LD_LIBRARY_PATH
" >> ~/.profile_extras
fi

# needed for some packages
ln -sf /dev $FAPT_ROOT/
ln -sf /sbin $FAPT_ROOT/


# needed for apt to work
mkdir -p $FAPT_ROOT/var/cache/apt/archives/partial
cp -rf /var/lib/apt/ $FAPT_ROOT/var/lib/
mkdir -p $FAPT_ROOT/var/lib/apt/lists/partial


mkdir -p $FAPT_ROOT/var/log/
mkdir -p $FAPT_ROOT/var/lib/dpkg
cp -rf /var/lib/dpkg/ $FAPT_ROOT/var/lib/ || true
mkdir -p $FAPT_ROOT/etc/apt/
echo "
Dir
{
  Root \"${FAPT_ROOT}\";
  Cache \"${FAPT_ROOT}/var/cache/apt/\";
  State \"${FAPT_ROOT}/var/lib/apt/\";
  Etc
  {
    SourceList \"${FAPT_ROOT}/etc/apt/sources.list\";
    SourceParts \"${FAPT_ROOT}/etc/apt/sources.list.d/\";
  }
};

Debug
{
  NoLocking \"1\";
  pkgDPkgPM \"1\";
};

DPkg 
{
  Options {\"--force-overwrite\";\"--root=${FAPT_ROOT}\";\"--force-not-root\";\"--log=${FAPT_ROOT}/var/log/dpkg.log\";}
}
" > $FAPT_ROOT/etc/apt/apt.conf

mkdir -p $FAPT_ROOT/etc/apt/sources.list.d
ln -s /etc/apt/sources.list.d/* $FAPT_ROOT/etc/apt/sources.list.d/
ln -s /etc/apt/sources.list $FAPT_ROOT/etc/apt/sources.list.d/orig.list
touch $FAPT_ROOT/etc/apt/sources.list

mkdir -p $FAPT_ROOT/usr/bin
cp -f $SCRIPT_DIR/fapt.sh $FAPT_ROOT/usr/bin/fapt
chmod +x $FAPT_ROOT/usr/bin/fapt

apt-get -c ${FAPT_ROOT}/etc/apt/apt.conf update

source ~/.profile_extras

echo "Ok, the installation's done. Happy fapt-ing!"
