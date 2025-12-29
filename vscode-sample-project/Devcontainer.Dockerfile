# This Dockerfile is used to build the image used by the devcontainer.json file.
# This is used setting up the development environment in VS Code.
FROM swift:5.9.1-jammy

ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Install essentials
RUN apt-get update && \
    apt-get install -y wget

# Install mongosh
RUN wget -qO- https://www.mongodb.org/static/pgp/server-7.0.asc | tee /etc/apt/trusted.gpg.d/server-7.0.asc > /dev/null && \
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-7.0.list && \
    apt-get update && \
    apt-get install -y mongodb-mongosh mongodb-database-tools

# Add non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    # Add sudo support for the non-root user
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME

# Install Mint
RUN cd && \
    git clone https://github.com/yonaskolb/Mint.git &&\
    cd Mint &&\
    swift run mint install yonaskolb/mint
ENV PATH="/home/${USERNAME}/.mint/bin:${PATH}"

# Local project Mint dependencies
COPY Mintfile /Mintfile
RUN mint bootstrap --link --mintfile /Mintfile

# Required for non-root user with anonymous volume on these paths to be able to build
RUN sudo mkdir -p /workspace/.build && \
    sudo chown $USERNAME:$USERNAME /workspace/.build