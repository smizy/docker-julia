FROM alpine:3.7

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL \
    maintainer="smizy" \
    org.label-schema.build-date=$BUILD_DATE \
    org.label-schema.docker.dockerfile="/Dockerfile" \
    org.label-schema.license="Apache License 2.0" \
    org.label-schema.name="smizy/julia" \
    org.label-schema.url="https://github.com/smizy" \
    org.label-schema.vcs-ref=$VCS_REF \
    org.label-schema.vcs-type="Git" \
    org.label-schema.version=$VERSION \
    org.label-schema.vcs-url="https://github.com/smizy/docker-julia"

ENV JUPYTER       /usr/bin/jupyter 
ENV JULIA_PKGDIR  /home/jupyter/.julia
ENV PYTHON        /usr/bin/python3

RUN set -x \
    && apk update \
    && apk --no-cache add \
        bash \
        freetype \
        julia \
        mbedtls \
        python3 \
#        py3-zmq \
        py3-tornado \
        su-exec \ 
        tini \
    && apk --no-cache add --virtual .builddeps \
        build-base \
        cmake \
        freetype-dev \
        openblas-dev \
        perl \
        python3-dev \
    && pip3 install --upgrade pip \
    && pip3 install jupyter \
    # matplotlib for PyPlot
    && ln -s /usr/include/locale.h /usr/include/xlocale.h \
    && pip3 install numpy==1.13.3 \
    && pip3 install matplotlib \
    # dir/user
    && mkdir -p \
        /etc/jupyter \
        ${JULIA_PKGDIR} \
    && adduser -D  -g '' -s /sbin/nologin -u 1000 docker \
    && adduser -D  -g '' -s /sbin/nologin jupyter \
    && addgroup jupyter docker \
    # jupyter julia kernel
    && julia -e 'Pkg.init()' \
    # MbedTLS workaround
    && julia -e 'Pkg.clone("MbedTLS")' \
    && cd $JULIA_PKGDIR/v0.6/MbedTLS \
    && sed -ri 's/^(const juliaprefix = )(joinpath.+)$/\1Prefix(\2)/' deps/build.jl \
    && julia $JULIA_PKGDIR/v0.6/MbedTLS/deps/build.jl \
    && julia -e 'Pkg.add("IJulia")' \
    && jupyter kernelspec list \
    && jupyter kernelspec install /root/.local/share/jupyter/kernels/julia-* \
    && julia -e 'using IJulia;' \
    # PyPlot
    && julia -e 'Pkg.add("PyPlot"); using PyPlot;' \
    # CodecZlib.jl: force to search path /lib/libz.so
    && julia -e 'Pkg.add("CSV");' \
    && julia $JULIA_PKGDIR/v0.6/CodecZlib/deps/build.jl / \
    && julia -e 'using CSV' \
    # 
    && chown -R jupyter:jupyter /home/jupyter \
    # clean
    && find /usr/lib/python3.6 -name __pycache__ | xargs rm -r \
    && rm -rf /root/.[acpw]* \
    && apk del .builddeps   

RUN set -x \
    # PyPlot: Error loading shared library /usr/lib/libpython3.6m.so
    && ln -s /usr/lib/libpython3.6m.so.1.0 /usr/lib/libpython3.6m.so

USER jupyter

WORKDIR /code

COPY entrypoint.sh  /usr/local/bin/
COPY jupyter_notebook_config.py /etc/jupyter/

EXPOSE 8888

ENTRYPOINT ["/sbin/tini", "--", "entrypoint.sh"]
CMD ["jupyter", "notebook"]