# Ubuntu 26.04 LTS ships Ruby 3.x, enough for the scripts in scripts/.
# Go is not needed: the Hextra theme is vendored in _vendor/.
FROM ubuntu:26.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
  ca-certificates \
  git \
  ruby \
  wget \
  && rm -rf /var/lib/apt/lists/*

ARG HUGO_VERSION=0.170.0
RUN ARCH=$(dpkg --print-architecture) && \
  wget -q https://github.com/gohugoio/hugo/releases/download/v${HUGO_VERSION}/hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb && \
  dpkg -i hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb && \
  rm hugo_extended_${HUGO_VERSION}_linux-${ARCH}.deb

WORKDIR /app

COPY . .

RUN ./scripts/generate_index.rb

RUN hugo

EXPOSE 1313

CMD ["hugo", "server", "--logLevel", "debug", "--disableFastRender", "-p", "1313", "--bind", "0.0.0.0"]
