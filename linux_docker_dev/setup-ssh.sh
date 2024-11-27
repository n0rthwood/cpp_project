#!/bin/bash

# Generate host keys if they don't exist
ssh-keygen -A

# Set up authorized keys if provided
if [ -f /tmp/id_rsa.pub ]; then
    cp /tmp/id_rsa.pub /home/developer/.ssh/authorized_keys
    chown developer:developer /home/developer/.ssh/authorized_keys
    chmod 600 /home/developer/.ssh/authorized_keys
fi

# Ensure SSH directory permissions are correct
chown -R developer:developer /home/developer/.ssh
chmod 700 /home/developer/.ssh
