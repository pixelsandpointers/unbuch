FROM nixos/nix AS builder
RUN mkdir -p /etc/nix 
RUN echo "experimental-features = nix-command flakes" >> /etc/nix/nix.conf
RUN mkdir /workspace
COPY . /workspace
WORKDIR /workspace
