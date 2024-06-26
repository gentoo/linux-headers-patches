#!/bin/bash -ex

ver=$1
if [[ -z $ver ]]; then
	echo "Usage: $0 <kernel ver>"
	exit 1
fi
[[ ${ver} == linux-* ]] && ver=${ver#linux-}
ver=${ver%/}

src=linux-${ver}
dst=gentoo-headers-base-${ver}
distdir=$(portageq distdir)

if [ ! -d ${src} ] ; then
	for srcdir in . "${distdir}" /var/cache/distfiles /usr/portage/distfiles ; do
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
	wget https://www.kernel.org/pub/linux/kernel/v${ver:0:1}.x/linux-${ver}.tar.xz -P "${distdir}"
	exec "$0" "$@"
fi

rm -rf ${dst}
mkdir ${dst}
cp ${src}/Makefile ${dst}/
mkdir ${dst}/include
[ -f ${src}/include/Kbuild ] && cp ${src}/include/Kbuild ${dst}/include/
directories=$(find ${src}/include -mindepth 2 -maxdepth 2 -name 'Kbuild*' -printf %h' ')
if [ -n "${directories}" ] ; then
	cp -r ${directories} ${dst}/include/
else
	cp -r ${src}/include/* ${dst}/include
fi
mkdir ${dst}/scripts
cp -r \
	${src}/scripts/{Makefile,Kbuild}* \
	${src}/scripts/unifdef.c \
	${src}/scripts/*.{sh,pl} \
	${dst}/scripts/
if [[ -f ${src}/scripts/subarch.include ]]; then
	cp ${src}/scripts/subarch.include ${dst}/scripts/
fi
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
# handle x86 unique headers
if [[ -e ${src}/arch/x86/entry/syscalls ]] ; then
	mkdir -p ${dst}/arch/x86/entry
	cp -r ${src}/arch/x86/entry/syscalls ${dst}/arch/x86/entry/
fi
# mips has some unique headers as well
if [[ -e ${src}/arch/mips/Kbuild.platforms ]] ; then
	for f in "${src}"/arch/mips/*/Platform ; do
		f=${f#${src}}
		mkdir ${dst}/${f%/*}
		cp ${src}/${f} ${dst}/${f}
	done
fi
if [[ -d ${src}/arch/mips/boot/tools ]] ; then
	mkdir -p ${dst}/arch/mips/boot
	cp -r ${src}/arch/mips/boot/tools ${dst}/arch/mips/boot/
fi
# linux-5.0 started generating syscall tables
for tblgen in ${src}/arch/*/kernel/syscalls; do
	tblgen_parent=${tblgen#${src}/}
	tblgen_parent=${tblgen_parent%/syscalls}
	# older kernels have none
	if [[ -d ${tblgen} ]]; then
		mkdir -p ${dst}/${tblgen_parent}
		cp -r ${tblgen} ${dst}/${tblgen_parent}
	fi
done
find ${dst}/ -name .gitignore -delete

cp README.ripped-headers rip-headers.sh ${dst}/

compress=xz
tar cf - ${dst} | ${compress} > ${dst}.tar.${compress}
rm -rf ${dst}
ls -lh ${dst}.tar.${compress}
