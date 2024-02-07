# Use the official Jenkins image from Docker Hub
FROM jenkins/jenkins:latest

# Switch to root user to install necessary packages
USER root

# Install Docker prerequisites
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Add Docker's official GPG key
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -

# Add Docker repository for Debian
RUN echo "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
RUN apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io

# Switch back to the Jenkins user
USER jenkins

