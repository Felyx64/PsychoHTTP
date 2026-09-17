FROM fedora:44
WORKDIR /out
RUN ./server.out
EXPOSE 7870
