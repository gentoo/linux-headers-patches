#!/bin/bash

if [[ $# -ne 2 ]] ; then
	echo "Usage: $0 <kernel ver> <patch ver>"
	exit 1
fi

kver=$1
pver=$2
if [[ ! -d $kver ]] ; then
	echo "dir '$kver' does not exist"
	exit 1
fi

tar=gentoo-headers-${kver}-${pver}.tar.lzma
rm -f gentoo-headers-${kver}-*.tar.lzma

if [[ -n $(find $kver -name '??_all_*') ]] ; then
	ch=
else
	ch="-C .tmp"
	rm -rf .tmp
	mkdir .tmp
	cp -r $kver .tmp/
	pushd .tmp/$kver >/dev/null
	for p in *.patch ; do
		mv $p 00_all_$p
	done
	popd >/dev/null
fi

tar -cf - --exclude=CVS $ch $kver | lzma > ${tar}

rm -rf .tmp
du -b *.lzma
