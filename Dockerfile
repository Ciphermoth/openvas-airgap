FROM immauss/ovasbase:latest AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ARG TAG
ENV VER="$TAG"

RUN mkdir /build.d
COPY build.rc /
#COPY build.d/package-list-build /build.d/
COPY build.d/build-prereqs.sh /build.d/
COPY ver.current /
RUN bash /build.d/build-prereqs.sh
#COPY build.d/update-certs.sh /build.d/
#RUN bash /build.d/update-certs.sh

# Copy pre-downloaded source code
COPY src/gvm-libs /src/gvm-libs
COPY src/openvas-smb /src/openvas-smb
COPY src/gvmd /src/gvmd
COPY src/openvas-scanner /src/openvas-scanner
COPY src/ospd-openvas /src/ospd-openvas
COPY src/gvm-tools /src/gvm-tools
COPY src/notus-scanner /src/notus-scanner
COPY src/gsad /src/gsad

# Adjust build scripts to use local source paths
COPY build.d/gvm-libs.sh /build.d/
RUN bash /build.d/gvm-libs.sh /src/gvm-libs

COPY build.d/openvas-smb.sh /build.d/
RUN bash /build.d/openvas-smb.sh /src/openvas-smb

COPY build.d/gvmd.sh /build.d/
RUN bash /build.d/gvmd.sh /src/gvmd

COPY build.d/openvas-scanner.sh /build.d/
RUN bash /build.d/openvas-scanner.sh /src/openvas-scanner

COPY build.d/ospd-openvas.sh /build.d/
RUN bash /build.d/ospd-openvas.sh /src/ospd-openvas

COPY build.d/gvm-tool.sh /build.d/
RUN bash /build.d/gvm-tool.sh /src/gvm-tools

COPY build.d/notus-scanner.sh /build.d/
RUN bash /build.d/notus-scanner.sh /src/notus-scanner

COPY build.d/gsad.sh /build.d/
RUN bash /build.d/gsad.sh /src/gsad

COPY build.d/gb-feed-sync.sh /build.d/
RUN bash /build.d/gb-feed-sync.sh

COPY build.d/links.sh /build.d/
RUN bash /build.d/links.sh

# Stage 1: Runtime image
FROM immauss/ovasbase:latest AS slim
LABEL maintainer="scott@immauss.com" \
      version="$VER-slim"
EXPOSE 9392
ENV LANG=C.UTF-8

COPY --from=0 etc/gvm/pwpolicy.conf /usr/local/etc/gvm/pwpolicy.conf
COPY --from=0 etc/logrotate.d/gvmd /etc/logrotate.d/gvmd

COPY --from=0 lib/systemd/system /lib/systemd/system
COPY --from=0 usr/local/bin /usr/local/bin
COPY --from=0 usr/local/include /usr/local/include
COPY --from=0 usr/local/lib /usr/local/lib
COPY --from=0 usr/local/sbin /usr/local/sbin
COPY --from=0 usr/local/share /usr/local/share
COPY --from=0 usr/share/postgresql /usr/share/postgresql
COPY --from=0 usr/lib/postgresql /usr/lib/postgresql

COPY confs/* /usr/local/etc/gvm/
COPY build.d/links.sh /
RUN bash /links.sh
COPY build.d/gpg-keys.sh /
RUN bash /gpg-keys.sh
COPY gsa-final/ /usr/local/share/gvm/gsad/web/
COPY build.rc /gvm-versions
COPY branding/* /branding/
RUN bash /branding/branding.sh
COPY scripts/* /scripts/
COPY ver.current /

HEALTHCHECK --interval=300s --start-period=300s --timeout=120s \
  CMD /scripts/healthcheck.sh || exit 1
ENTRYPOINT [ "/scripts/start.sh" ]

# Stage 2: Final image with database
FROM slim AS final
LABEL maintainer="scott@immauss.com" \
      version="$VER-full"

#COPY globals.sql.xz /usr/lib/globals.sql.xz
#COPY gvmd.sql.xz /usr/lib/gvmd.sql.xz
#COPY var-lib.tar.xz /usr/lib/var-lib.tar.xz
COPY scripts/* /scripts/

HEALTHCHECK --interval=300s --start-period=300s --timeout=120s \
CMD /scripts/healthcheck.sh || exit 1
ENTRYPOINT [ "/scripts/start.sh" ]
