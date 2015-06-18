FROM ubuntu:14.04

WORKDIR /tmp
ENV cross_base /opt/cross
ENV PATH=$cross_base:$PATH

RUN \
  sed -i 's/# \(.*multiverse$\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y build-essential && \
  apt-get install -y software-properties-common && \
  apt-get install -y mercurial g++ gcc libtool make wget curl && \
  rm -rf /var/lib/apt/lists/* && \
  hg clone https://bitbucket.org/GregorR/musl-cross && \
  echo "GCC_BUILTIN_PREREQS=yes" >> musl-cross/config.sh && \
  echo "ARCH=x86_64" >> musl-cross/config.sh && \
  cd musl-cross && ./build.sh && \
  cd /tmp && curl -L http://ftp.gnu.org/gnu/ncurses/ncurses-5.9.tar.gz | \
  gunzip -c - | tar xf - && \
  perl -pi -e 's/linux\-uclibc/linux\-musl/g' ncurses*/config.sub && \
  cd ncurses-5.9 && ./configure --target=$musl_triple --with-gcc=$musl_triple-gcc --with-shared --host=$musl_triple --with-build-cpp=$musl_triple-g++ --prefix=$cross_base/$musl_triple/$musl_triple && \
  make && \
  make install && \
  cd $cross_base/$musl_triple/$musl_triple/include/ncurses && cp *.h .. && \
  cd /tmp && rm -fr musl-cross ncurses-5.9

CMD ["bash"]
