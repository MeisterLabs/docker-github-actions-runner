# hadolint ignore=DL3007
FROM myoung34/github-runner-base:ubuntu-noble
LABEL maintainer="myoung34@my.apsu.edu"

ENV RUN_AS_ROOT="false"
ENV DEBIAN_FRONTED="noninteractive"
ENV AGENT_TOOLSDIRECTORY=/opt/hostedtoolcache
RUN mkdir -p /opt/hostedtoolcache

ARG GH_RUNNER_VERSION="2.322.0"
ARG TARGET_BASE_FILE
ARG TARGET_PRODUCT_FILE
ARG TARGETPLATFORM

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    tzdata \
    libmysqlclient-dev

WORKDIR /actions-runner
COPY install_actions.sh /actions-runner

RUN chmod +x /actions-runner/install_actions.sh \
  && /actions-runner/install_actions.sh ${GH_RUNNER_VERSION} ${TARGETPLATFORM} \
  && rm /actions-runner/install_actions.sh \
  && chown runner /_work /actions-runner /opt/hostedtoolcache

COPY token.sh entrypoint.sh app_token.sh /
RUN chmod +x /token.sh /entrypoint.sh /app_token.sh

# Fix the permission issue on the docker containers
COPY permissions.sh /runner

#Install common packages
COPY /commons/common.sh /common.sh
RUN chmod +x /common.sh
RUN bash /common.sh

#Install base packages
COPY /bases/$TARGET_BASE_FILE /$TARGET_BASE_FILE
RUN chmod +x /$TARGET_BASE_FILE
RUN bash /$TARGET_BASE_FILE

#Install product specifics
COPY /products/$TARGET_PRODUCT_FILE /$TARGET_PRODUCT_FILE
RUN chmod +x /$TARGET_PRODUCT_FILE
RUN bash /$TARGET_PRODUCT_FILE

USER runner

ENTRYPOINT ["/entrypoint.sh & /permissions.sh"]
CMD ["./bin/Runner.Listener", "run", "--startuptype", "service"]
