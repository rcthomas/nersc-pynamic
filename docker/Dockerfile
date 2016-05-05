FROM centos:6.6
RUN yum upgrade -y && \
    yum install -y \
        python-devel \
        gcc && \
        mkdir /bench

## install optcray stuff
ADD optcray_cori.tar /

RUN echo "/opt/cray/mpt/default/gni/mpich2-gnu/49/lib" >> /etc/ld.so.conf && \
    echo "/opt/cray/pmi/default/lib64" >> /etc/ld.so.conf && \
    echo "/opt/cray/ugni/default/lib64" >> /etc/ld.so.conf && \
    echo "/opt/cray/udreg/default/lib64" >> /etc/ld.so.conf && \
    echo "/opt/cray/xpmem/default/lib64" >> /etc/ld.so.conf && \
    echo "/opt/cray/alps/default/lib64" >> /etc/ld.so.conf && \
    echo "/opt/cray/wlm_detect/default/lib64" >> /etc/ld.so.conf && \
    echo "/bench" >> /etc/ld.so.conf && \
    ldconfig

ADD https://github.com/LLNL/pynamic/archive/1.3.tar.gz /bench && \
    cd /bench/pynamic-pyMPI-2.6a1 && \
    mv * ..

RUN cd /bench && \
    LDFLAGS="-lpython2.6 -L/opt/cray/mpt/default/gni/mpich-gnu/5.1/lib -lmpich_gnu_51" \
    ./config_pynamic.py 495 1850 -e -u 215 1850 -n 100 -c \
        --with-includes="-I/opt/cray/mpt/default/gni/mpich-gnu/5.1/include" && \
    chmod -R a+rX /bench && \
    ldconfig
