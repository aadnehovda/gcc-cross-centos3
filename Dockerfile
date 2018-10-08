FROM centos:6

RUN yum -y upgrade && yum -y install wget file bison flex make gcc-c++ binutils && yum clean all

ADD centos3.repo /etc/yum.repos.d/

ARG platform=x86_64-centos3-linux-gnu
ARG prefix=/opt/toolchains

RUN yum --disablerepo=\* \
	--enablerepo=\*-centos3 \
	--installroot $prefix/$platform/sys-root \
	install -y XFree86-devel.x86_64 glibc-devel.x86_64 \
	&& rm -fr $prefix/$platform/sys-root/{etc,bin,boot,root,home,initrd,mnt,sbin,opt,proc,dev,tmp,var,usr/{bin,dict,etc,games,libexec,local,sbin,share,src,tmp}}

ARG binutils=2.31
RUN (curl http://gnuftp.uib.no/binutils/binutils-$binutils.tar.gz | tar -xzf-) \
	&& mkdir binutils-build \
	&& pushd binutils-build \
	&& ../binutils-$binutils/configure --prefix=$prefix --enable-gold --disable-nls --with-sysroot --target=$platform --host=x86_64-redhat-linux --build=x86_64-redhat-linux \
	&& make -j$(nproc) \
	&& make install-strip \
	&& popd \
	&& rm -fr binutils-build binutils-$binutils

ARG gcc=5.5.0
RUN (curl http://gnuftp.uib.no/gcc/gcc-$gcc/gcc-$gcc.tar.gz | tar -xzf-) \
	&& pushd gcc-$gcc \
	&& ./contrib/download_prerequisites \
	&& popd \
	&& mkdir gcc-build \
	&& pushd gcc-build \
	&& ../gcc-$gcc/configure --prefix=$prefix --target=$platform --build=x86_64-redhat-linux --host=x86_64-redhat-linux --with-sysroot --disable-multilib --disable-libcilkrts --disable-libsanitizer --enable-languages=c,c++ --disable-nls \
	&& make -j$(nproc) \
	&& make install-strip \
	&& popd \
	&& rm -fr gcc-build gcc-$gcc

ENV PATH=$PATH:$prefix/bin

ARG cmake=3.12.3
RUN curl https://cmake.org/files/v3.12/cmake-$cmake-Linux-x86_64.tar.gz | tar --strip-components=1 -C /usr -xzf-

ARG ninja=1.8.2
RUN yum -y install unzip \
	&& yum clean all \
	&& curl -L -o ninja.zip https://github.com/ninja-build/ninja/releases/download/v$ninja/ninja-linux.zip \
	&& unzip -d /usr/bin ninja.zip \
	&& rm ninja.zip

ADD $platform.cmake $prefix
