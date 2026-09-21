FROM fedora:44
WORKDIR /out
COPY . .
CMD ["./server.out"]
EXPOSE 7870
