
ARG ruby_version=3.4.8
ARG pg_major=18

FROM docker.io/library/ruby:${ruby_version}-slim AS base

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl build-essential git libpq-dev libyaml-dev pkg-config \
      postgresql-common

RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y && \
    apt-get install --no-install-recommends -y postgresql-client-18 bind9-dnsutils

RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash
USER 1000:1000

WORKDIR /opt/app
