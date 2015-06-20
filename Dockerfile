FROM ubuntu:14.04

WORKDIR /tmp
ENV cross_base /opt/cross
ENV cross_arch x86_64
ENV cross_os linux
ENV cross_libc musl
ENV musl_triple $cross_arch-$cross_os-$cross_libc
ENV cross_path $cross_base/$musl_triple
ENV cross_prefix $cross_path/$musl_triple
ENV cross_lib $cross_prefix/lib
ENV cross_bin $cross_path/bin
ENV cross_include $cross_prefix/include

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  add-apt-repository -y ppa:hvr/ghc && \
  apt-get install -y mercurial g++ gcc libtool make wget curl && \
  hg clone https://bitbucket.org/GregorR/musl-cross && \
  echo GCC_BUILTIN_PREREQS=yes >> musl-cross/config.sh && \
  echo ARCH=$cross_arch >> musl-cross/config.sh && \
  cd musl-cross && ./build.sh && \
  rm -fr musl-cross

RUN \
  cd /tmp && curl -L http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz | \
  gunzip -c - | tar xf - && \
  perl -pi -e 's/linux\-uclibc/linux\-musl/g' ncurses*/config.sub && \
  cd ncurses-5.9 && ./configure --target=$musl_triple \
  --with-gcc=$musl_triple-gcc \
  --with-shared \
  --host=$musl_triple \
  --with-build-cpp=$musl_triple-g++ \
  --prefix=$cross_prefix && \
  make && \
  make install && \
  cp $cross_include/ncurses/*.h $cross_include && \
  cd /tmp && rm -fr ncurses-5.9

ENV PATH $cross_bin:$PATH
ENV LD_LIBRARY_PATH $cross_lib:$LD_LIBRARY_PATH

CMD ["bash"]
