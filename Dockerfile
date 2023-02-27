FROM alpine:3.17 as builder

LABEL maintainer="Michael Trip <m.trip@atcomputing.nl>"
# Build stage


RUN apk update && \
    apk --no-cache upgrade && \
    apk --no-cache add python3-dev~=3.10 \
        py3-pip~=22.3 \
        build-base~=0.5 \
        libffi-dev~=3.4
COPY src/requirements.txt /tmp

WORKDIR /app

RUN mkdir -p /app/ansible && \
    python3 -m venv /app/ansible && \
    source /app/ansible/bin/activate && \
    pip --no-cache-dir install -r /tmp/requirements.txt

# This will do the actual work

FROM alpine:3.17

# This environment variable is used to force ansible to use scp instead of sftp. This due the fact that alpine only uses openssh-client 9, where the default method is sftp. But packer doesn´t like that:
# https://github.com/hashicorp/packer-plugin-ansible/issues/100
ENV ANSIBLE_SCP_EXTRA_ARGS=-O

RUN mkdir -p /app/ansible

COPY --from=builder /app/ansible/ /app/ansible/
RUN adduser -D -u 1001 packer
RUN apk update && \
    apk --no-cache upgrade && \
    apk --no-cache add packer~=1.8.4 \
            python3~=3.10 \
            openssh-client~=9.1 \
            sshpass~=1.09

WORKDIR /app
COPY template.pkr.hcl .
COPY ansible/playbook.yml .
COPY scripts/entrypoint.sh .
RUN chmod +x /app/entrypoint.sh
WORKDIR /app
USER packer
ENTRYPOINT [ "/app/entrypoint.sh" ]