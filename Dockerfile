# Official Ruby image on Debian 13 "trixie" (supported until 2028, Debian LTS until 2030-06-30).
# Same Ruby major as CI and local (4.0). No Go or git needed: the Hextra theme is vendored in _vendor/.

# Stage 1: fetch Hugo Extended from the official release tarball (the .deb exists only for amd64).
# TARGETARCH is set by BuildKit: amd64 or arm64 (Apple Silicon).
FROM ruby:4.0-slim-trixie AS hugo
ARG HUGO_VERSION=0.170.0
ARG TARGETARCH
ADD https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${TARGETARCH}.tar.gz /tmp/hugo.tar.gz
RUN tar -xzf /tmp/hugo.tar.gz -C /usr/local/bin hugo

# Stage 2: the image that runs the site
FROM ruby:4.0-slim-trixie
COPY --from=hugo /usr/local/bin/hugo /usr/local/bin/hugo
RUN hugo version

WORKDIR /app

COPY . .

RUN ./scripts/generate_index.rb

RUN hugo

EXPOSE 1313

CMD ["hugo", "server", "--logLevel", "debug", "--disableFastRender", "-p", "1313", "--bind", "0.0.0.0"]
