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
tar -cf - --exclude="$kver/CVS" $kver | lzma > ${tar}

du -b *.lzma
