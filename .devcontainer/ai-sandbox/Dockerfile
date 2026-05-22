FROM ubuntu:24.04

# 基本システムパッケージのインストール
RUN apt-get update && apt-get install -y \
    build-essential curl git sudo zsh \
    ca-certificates gnupg \
    && rm -rf /var/lib/apt/lists/*

# ubuntu ユーザーに sudo 権限を付与
RUN echo "ubuntu ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ubuntu
ENV HOME=/home/ubuntu

# Homebrew のインストール
RUN NONINTERACTIVE=1 /bin/bash -c \
    "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/ubuntu/.local/bin:$PATH"
