#!/bin/bash -ex

ver=$1
[[ -z $ver ]] && exit 1

src=linux-${ver}
dst=gentoo-headers-base-${ver}

rm -rf ${dst}
mkdir ${dst}
cp ${src}/Makefile ${dst}/
mkdir ${dst}/include
cp ${src}/include/Kbuild ${dst}/include/
cp -r $(find ${src}/include -mindepth 2 -maxdepth 2 -name Kbuild -printf %h' ') ${dst}/include/
mkdir ${dst}/scripts
cp -r ${src}/scripts/{Makefile,Kbuild}* ${src}/scripts/unifdef.c ${src}/scripts/basic ${dst}/scripts/
mkdir ${dst}/arch
arches=$(cd ${src}/arch ; ls)
for a in ${arches} ; do
	[[ ! -e ${src}/include/asm-${a}/Kbuild ]] && continue
	mkdir -p ${dst}/arch/${a}
	cp ${src}/arch/${a}/Makefile ${dst}/arch/${a}/
done

cp README.ripped-headers rip-headers.sh ${dst}/

tar jcf ${dst}.tar.bz2 ${dst}
rm -rf ${dst}
ls -lh ${dst}.tar.bz2
