FROM jenkins/inbound-agent@sha256:0c5908a376ff73381f3617c8277b77559a9c8916fe0c22efd9b9e9ef326aeb27
USER root
RUN apt-get update \
 && apt-get install -y --no-install-recommends python3 python3-venv python3-pip zip unzip curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*
COPY --from=docker:29-cli /usr/local/bin/docker /usr/local/bin/docker
COPY --from=docker:29-cli /usr/local/libexec/docker/cli-plugins/docker-buildx /usr/local/libexec/docker/cli-plugins/docker-buildx
RUN curl -sSfL "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o /tmp/awscliv2.zip \
 && unzip -q /tmp/awscliv2.zip -d /tmp && /tmp/aws/install \
 && rm -rf /tmp/aws /tmp/awscliv2.zip
USER jenkins
