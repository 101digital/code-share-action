FROM alpine

LABEL org.opencontainers.image.source https://github.com/101digital/code-share-action.git

RUN   apk add --no-cache --update bash git git-lfs less openssh curl

WORKDIR /

COPY fillbucket.sh /

ENTRYPOINT [ "/fillbucket.sh" ]
