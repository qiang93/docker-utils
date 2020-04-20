ARG REDIS_VERSION_TAG="4.0"
ARG DOCKER_VERSION_TAG="19.03.8"
ARG PYTHON_VERSION_TAG="3.8-buster"

FROM redis:${REDIS_VERSION_TAG} as redis

FROM docker:${DOCKER_VERSION_TAG} as docker

FROM python:${PYTHON_VERSION_TAG}

# apt-get
# - gnupg is for `gpg`
# - dirmngr is missing when calling gpg
# - dnsutils is for `dig`
# - gettext-base is for `envsubst`
# - net-tools is for `netstat`
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        apt-transport-https \
        vim \
        git \
        jq \
        dnsutils \
        telnet \
        traceroute \
        curl \
        gettext-base \
        gawk \
        sed \
        tar \
        unzip \
        socat \
        rsync \
        net-tools \
        ssh \
        gnupg \
        dirmngr \
        less \
        iputils-ping \
        bash-completion

# pip3
RUN pip3 --no-cache-dir install \
    yq


ARG GIT_AUTO_COMPLETION_URL=https://github.com/git/git/blob/master/contrib/completion/git-completion.bash

# curl aws-iam-authenticator
ENV BIN_PATH=/usr/local/bin \
    TMP_PATH=/tmp \
    EDITOR=vim \
    KUBECONFIG=/root/.kube/kubeconfig.yaml

# pre commands

# apt-get kubectl
ARG KUBECTL_VERSION="1.15.9-00"
RUN curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg \
        | apt-key add - \
    && touch /etc/apt/sources.list.d/kubernetes.list \
    && echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" \
        | tee -a /etc/apt/sources.list.d/kubernetes.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        kubectl=$KUBECTL_VERSION \
    && ln -s /usr/bin/kubectl /usr/bin/ku

# ARG HEPTIO_URL=https://amazon-eks.s3-us-west-2.amazonaws.com/1.12.7/2019-03-27/bin/linux/amd64/aws-iam-authenticator
# RUN curl -L $HEPTIO_URL \
#         -o $BIN_PATH/aws-iam-authenticator \
#     && chmod +x $BIN_PATH/aws-iam-authenticator \
#     && ln -s $BIN_PATH/aws-iam-authenticator $BIN_PATH/heptio-authenticator-aws

# # sops
# ARG SOPS_VERSION="3.3.1"
# RUN curl -L https://github.com/mozilla/sops/releases/download/$SOPS_VERSION/sops-$SOPS_VERSION.linux \
#         -o $BIN_PATH/sops \
#     && chmod +x $BIN_PATH/sops

# curl helm
ARG HELM_VERSION="v2.16.6"
ARG HELM_URL=https://storage.googleapis.com/kubernetes-helm/helm-$HELM_VERSION-linux-amd64.tar.gz
ARG HELM_FOLDER=linux-amd64
ARG HELM_DIFF_URL=https://github.com/databus23/helm-diff
ARG HELM_DIFF_VERSION="2.11.0+5"
RUN curl -L $HELM_URL \
        -o $TMP_PATH/helm.tar.gz \
    && tar -xvf $TMP_PATH/helm.tar.gz -C $TMP_PATH $HELM_FOLDER \
    && mv $TMP_PATH/$HELM_FOLDER/helm $BIN_PATH \
    && mkdir -p $HOME/.helm/plugins \
    && helm plugin install $HELM_DIFF_URL --version $HELM_DIFF_VERSION \
    && helm init --client-only \
    && rm -rf $TMP_PATH/helm.tar.gz $TMP_PATH/$HELM_FOLDER \
    && helm repo remove stable local

# mongodb client
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 9DA31620334BD75D9DCB49F368818C72E52529D4 \
    && touch /etc/apt/sources.list.d/mongodb-org-4.0.list \
    && echo "deb http://repo.mongodb.org/apt/debian stretch/mongodb-org/4.0 main" \
        | tee /etc/apt/sources.list.d/mongodb-org-4.0.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
        mongodb-org-shell \
        mongodb-org-tools

# mysql/mariadb client
RUN apt-get install -y --no-install-recommends \
        mariadb-client

## post commands
RUN echo "alias ll='ls -lrt'" >> $HOME/.bashrc \
    && echo "source /etc/bash_completion" >> $HOME/.bashrc \
    && echo "source <(kubectl completion bash)" >> $HOME/.bashrc \
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && rm -rf /tmp/*

# redis client
COPY --from=redis /usr/local/bin/redis-cli /usr/local/bin/

# docker client
COPY --from=docker /usr/local/bin/docker /usr/local/bin/

WORKDIR /srv
COPY build/scripts scripts
COPY build/kubeconfig.yaml /root/.kube/
ENTRYPOINT ["/srv/scripts/entrypoint.sh"]
