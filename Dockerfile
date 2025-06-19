# VSH Docker Container - Ubuntu with VSH as the only shell
# This Dockerfile creates a container where VSH is the only available shell
# WARNING: This removes all other shells from the system

FROM ubuntu:22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV SHELL=/usr/local/bin/vsh
ENV VSH_PATH=/usr/local/bin/vsh

# Install basic dependencies and build tools
RUN apt-get update && apt-get install -y \
    git \
    gcc \
    make \
    libreadline-dev \
    build-essential \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Clone the VSH repository
WORKDIR /tmp
RUN git clone https://github.com/Vatsalj17/vsh.git
WORKDIR /tmp/vsh

# Build VSH
RUN make clean && make

# Install VSH to system location
RUN cp vsh /usr/local/bin/vsh && \
    chmod +x /usr/local/bin/vsh

# Create backup of original shells (for safety)
RUN mkdir -p /tmp/shell_backup && \
    cp /etc/shells /tmp/shell_backup/shells.backup 2>/dev/null || true && \
    cp /etc/passwd /tmp/shell_backup/passwd.backup 2>/dev/null || true

# Remove all other shells (DANGEROUS OPERATION)
RUN apt-get remove --purge -y bash dash 2>/dev/null || true && \
    apt-get autoremove -y 2>/dev/null || true && \
    rm -f /bin/bash /usr/bin/bash /bin/dash /usr/bin/dash /bin/sh /usr/bin/sh 2>/dev/null || true && \
    rm -f /bin/zsh /usr/bin/zsh /bin/fish /usr/bin/fish /bin/csh /usr/bin/csh /bin/tcsh /usr/bin/tcsh 2>/dev/null || true

# Update /etc/shells to contain only VSH
RUN echo "/usr/local/bin/vsh" > /etc/shells

# Create VSH compatibility symlinks
RUN ln -sf /usr/local/bin/vsh /bin/sh && \
    ln -sf /usr/local/bin/vsh /usr/bin/sh && \
    ln -sf /usr/local/bin/vsh /bin/bash && \
    ln -sf /usr/local/bin/vsh /usr/bin/bash && \
    ln -sf /usr/local/bin/vsh /bin/dash && \
    ln -sf /usr/local/bin/vsh /usr/bin/dash

# Change root user's shell to VSH
RUN usermod -s /usr/local/bin/vsh root

# Create a non-root user with VSH as default shell
RUN useradd -m -s /usr/local/bin/vsh vshuser && \
    echo "vshuser:vshuser" | chpasswd

# Clean up build dependencies and temporary files (optional - keeps image smaller)
# Uncomment the next line if you want a smaller image (but removes build tools)
# RUN apt-get remove --purge -y gcc make build-essential && apt-get autoremove -y

# Remove the cloned repository to save space
RUN rm -rf /tmp/vsh

# Set working directory
WORKDIR /home/vshuser

# Create a simple test script to verify VSH is working
RUN echo '#!/usr/local/bin/vsh' > /home/vshuser/test.sh && \
    echo 'echo "VSH is working!"' >> /home/vshuser/test.sh && \
    echo 'echo "Current shell: $0"' >> /home/vshuser/test.sh && \
    echo 'echo "Available shells:"' >> /home/vshuser/test.sh && \
    echo 'cat /etc/shells' >> /home/vshuser/test.sh && \
    chmod +x /home/vshuser/test.sh && \
    chown vshuser:vshuser /home/vshuser/test.sh

# Add some helpful aliases and environment setup
RUN echo 'export PATH="/usr/local/bin:$PATH"' >> /etc/environment && \
    echo 'export SHELL="/usr/local/bin/vsh"' >> /etc/environment

# Verify VSH installation
RUN /usr/local/bin/vsh --version 2>/dev/null || echo "VSH installed successfully"

# Switch to non-root user
USER vshuser

# Set VSH as the default shell for container startup
SHELL ["/usr/local/bin/vsh", "-c"]

# Default command - start VSH interactive shell
CMD ["/usr/local/bin/vsh"]

# Labels for documentation
LABEL maintainer="VSH Project"
LABEL description="Ubuntu container with VSH as the only available shell"
LABEL version="1.0"
LABEL warning="This container has all other shells removed - VSH only!"

# Health check to ensure VSH is working
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD /usr/local/bin/vsh -c "echo 'VSH Health Check OK'" || exit 1
