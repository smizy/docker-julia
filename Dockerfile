FROM alpine:3.7

ENV JUPYTER       /usr/bin/jupyter 
ENV JULIA_PKGDIR  /home/jupyter/.julia

RUN set -x \
    && apk update \
    && apk --no-cache add \
        bash \
        julia \
        python3 \
#        py3-zmq \
        py3-tornado \
        su-exec \ 
        tini \
    && apk --no-cache add --virtual .builddeps \
        build-base \
        cmake \
        openblas-dev \
        perl \
        python3-dev \
    && pip3 install --upgrade pip \
    && pip3 install jupyter \
    # dir/user
    && mkdir -p \
        /etc/jupyter \
        ${JULIA_PKGDIR} \
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin jupyter \
    && addgroup jupyter docker \
    # jupyter julia kernel
    && julia -e 'Pkg.init()' \
    && julia -e 'Pkg.add("IJulia")' \
    # ZMQ musl tgz require > 0.6
    && julia -e 'Pkg.checkout("ZMQ", "master")' \
    && julia -e 'Pkg.build("ZMQ")' \
    && jupyter kernelspec list \
    && jupyter kernelspec install /root/.local/share/jupyter/kernels/julia-* \
    && julia -e 'using IJulia;' \
    && chown -R jupyter:jupyter /home/jupyter \
    # clean
    && find /usr/lib/python3.6 -name __pycache__ | xargs rm -r \
    && rm -rf /root/.[acpw]* \
    && apk del .builddeps   

USER jupyter

RUN set -x \
    # CodecZlib.jl: force to search path /lib/libz.so
    && julia -e 'Pkg.add("CSV");' \
    && julia $JULIA_PKGDIR/v0.6/CodecZlib/deps/build.jl / \
    && julia -e 'using CSV' 


WORKDIR /code

COPY entrypoint.sh  /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

EXPOSE 8888

ENTRYPOINT ["/sbin/tini", "--", "entrypoint.sh"]
CMD ["jupyter", "notebook"]