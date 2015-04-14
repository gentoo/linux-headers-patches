#!/bin/bash -ex

ver=$1
[[ -z $ver ]] && exit 1
[[ ${ver} == linux-* ]] && ver=${ver#linux-}
ver=${ver%/}

src=linux-${ver}
dst=gentoo-headers-base-${ver}

if [ ! -d ${src} ] ; then
	for srcdir in . /usr/portage/distfiles ; do
		for ext in bz2 xz ; do
			srctar=${srcdir}/${src}.tar.${ext}
			if [ -e ${srctar} ] ; then
				tar xf ${srctar}
				break
			fi
		done
	done
fi
if [ ! -d ${src} ] ; then
	wget https://www.kernel.org/pub/linux/kernel/v${ver:0:1}.x/linux-${ver}.tar.xz -P /usr/portage/distfiles/
	exec "$0" "$@"
fi

rm -rf ${dst}
mkdir ${dst}
cp ${src}/Makefile ${dst}/
mkdir ${dst}/include
cp ${src}/include/Kbuild ${dst}/include/
cp -r $(find ${src}/include -mindepth 2 -maxdepth 2 -name 'Kbuild*' -printf %h' ') ${dst}/include/
mkdir ${dst}/scripts
cp -r \
	${src}/scripts/{Makefile,Kbuild}* \
	${src}/scripts/unifdef.c \
	${src}/scripts/*.{sh,pl} \
	${dst}/scripts/
mkdir -p ${dst}/scripts/basic
printf '#!/bin/sh\nexit 0' > ${dst}/scripts/basic/fixdep
chmod a+rx ${dst}/scripts/basic/fixdep
touch ${dst}/scripts/basic/Makefile

mkdir ${dst}/tools
cp -r \
	${src}/tools/include \
	${dst}/tools/

mkdir ${dst}/arch
arches=$(cd ${src}/arch ; ls)
for a in ${arches} ; do
	if [[ -e ${src}/include/asm-${a}/Kbuild ]] || [[ -e ${src}/arch/${a}/include/asm/Kbuild ]] ; then
		mkdir -p ${dst}/arch/${a}
		cp ${src}/arch/${a}/Makefile* ${dst}/arch/${a}/
		cp ${src}/arch/${a}/Kbuild* ${dst}/arch/${a}/ 2>/dev/null || :
		for d in include syscalls tools ; do
			if [[ -e ${src}/arch/${a}/${d} ]] ; then
				cp -r ${src}/arch/${a}/${d} ${dst}/arch/${a}/
			fi
		done
	fi
done
# mips has some stupid unique bs
if [[ -e ${src}/arch/mips/Kbuild.platforms ]] ; then
	for f in "${src}"/arch/mips/*/Platform ; do
		f=${f#${src}}
		mkdir ${dst}/${f%/*}
		cp ${src}/${f} ${dst}/${f}
	done
fi

cp README.ripped-headers rip-headers.sh ${dst}/

compress=xz
tar cf - ${dst} | ${compress} > ${dst}.tar.${compress}
rm -rf ${dst}
ls -lh ${dst}.tar.${compress}
