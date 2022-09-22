# Copyright 2022 Thoughtworks, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

###############################################################################################
# This file is autogenerated by the repository at https://github.com/gocd/gocd.
# Please file any issues or PRs at https://github.com/gocd/gocd
###############################################################################################

FROM curlimages/curl:latest as gocd-agent-unzip
USER root
ARG UID=1000
RUN curl --fail --location --silent --show-error "https://download.gocd.org/binaries/22.2.0-14697/generic/go-agent-22.2.0-14697.zip" > /tmp/go-agent-22.2.0-14697.zip
RUN unzip /tmp/go-agent-22.2.0-14697.zip -d /
RUN mv /go-agent-22.2.0 /go-agent && chown -R ${UID}:0 /go-agent && chmod -R g=u /go-agent

FROM docker.io/ubuntu:jammy

LABEL gocd.version="22.2.0" \
  description="GoCD agent based on docker.io/ubuntu:jammy" \
  maintainer="GoCD Team <go-cd-dev@googlegroups.com>" \
  url="https://www.gocd.org" \
  gocd.full.version="22.2.0-14697" \
  gocd.git.sha="4bdda4e0d769e66da651926c7066979740bd7ae7"

ADD https://github.com/krallin/tini/releases/download/v0.19.0/tini-static-amd64 /usr/local/sbin/tini

# force encoding
ENV LANG=en_US.UTF-8 LANGUAGE=en_US:en LC_ALL=en_US.UTF-8
ENV GO_JAVA_HOME="/gocd-jre"

ARG UID=1000
ARG GID=1000

####### CUSTOM ##########
RUN set -ex; \
    apt-get update && apt-get install -y --no-install-recommends \
        curl \
        sudo \
        ca-certificates \
        apt-transport-https; \
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -; \
    sudo apt-get install -y nodejs; 
####### END OF CUSTOM ##########

RUN \
# add mode and permissions for files we added above
  chmod 0755 /usr/local/sbin/tini && \
  chown root:root /usr/local/sbin/tini && \
# add our user and group first to make sure their IDs get assigned consistently,
# regardless of whatever dependencies get added
# add user to root group for GoCD to work on openshift
  useradd -u ${UID} -g root -d /home/go -m go && \
  apt-get update && \
  apt-get install -y git subversion mercurial openssh-client bash unzip curl locales procps sysvinit-utils coreutils && \
  apt-get autoclean && \
  echo 'en_US.UTF-8 UTF-8' > /etc/locale.gen && /usr/sbin/locale-gen && \
  curl --fail --location --silent --show-error 'https://github.com/adoptium/temurin17-binaries/releases/download/jdk-17.0.4%2B8/OpenJDK17U-jre_x64_linux_hotspot_17.0.4_8.tar.gz' --output /tmp/jre.tar.gz && \
  mkdir -p /gocd-jre && \
  tar -xf /tmp/jre.tar.gz -C /gocd-jre --strip 1 && \
  rm -rf /tmp/jre.tar.gz && \
  mkdir -p /go-agent /docker-entrypoint.d /go /godata

ADD docker-entrypoint.sh /


COPY --from=gocd-agent-unzip /go-agent /go-agent
# ensure that logs are printed to console output
COPY --chown=go:root agent-bootstrapper-logback-include.xml agent-launcher-logback-include.xml agent-logback-include.xml /go-agent/config/

RUN chown -R go:root /docker-entrypoint.d /go /godata /docker-entrypoint.sh \
    && chmod -R g=u /docker-entrypoint.d /go /godata /docker-entrypoint.sh


ENTRYPOINT ["/docker-entrypoint.sh"]

USER go
