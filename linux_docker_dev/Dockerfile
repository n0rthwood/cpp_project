# Use Ubuntu 22.04 LTS as the base image
FROM ubuntu:22.04

# Avoid prompts from apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required packages
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    python3 \
    python3-pip \
    python3-dev \
    openssh-server \
    sudo \
    ninja-build \
    curl \
    zip \
    unzip \
    tar \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Create developer user
RUN useradd -m -s /bin/bash developer \
    && echo "developer ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configure SSH
RUN mkdir /var/run/sshd
RUN echo 'developer:developer' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config

# Set up SSH directory for developer
RUN mkdir -p /home/developer/.ssh \
    && chown developer:developer /home/developer/.ssh \
    && chmod 700 /home/developer/.ssh

# Set up workspace directory
RUN mkdir -p /workspace \
    && chown developer:developer /workspace \
    && chmod 755 /workspace

# Install vcpkg as root
RUN git clone https://github.com/Microsoft/vcpkg.git /opt/vcpkg \
    && /opt/vcpkg/bootstrap-vcpkg.sh -disableMetrics \
    && chown -R developer:developer /opt/vcpkg

# Copy SSH setup script
COPY setup-ssh.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/setup-ssh.sh

# Switch to developer user
USER developer
WORKDIR /workspace

# Set environment variables
ENV VCPKG_ROOT=/opt/vcpkg
ENV CMAKE_TOOLCHAIN_FILE=/opt/vcpkg/scripts/buildsystems/vcpkg.cmake
ENV VCPKG_DISABLE_METRICS=1
ENV PATH="/opt/vcpkg:${PATH}"

# Start SSH server and run setup
CMD ["sh", "-c", "sudo /usr/local/bin/setup-ssh.sh && sudo /usr/sbin/sshd -D"]
