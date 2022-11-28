#!/bin/bash
# Set up a crescent service to join the goc-crescent chain.

# Configuration
# You should only have to modify the values in this block
PRIV_VALIDATOR_KEY_FILE=~/priv_validator_key.json
NODE_KEY_FILE=~/node_key.json
NODE_HOME=~/.crescent
NODE_MONIKER="<YOUR MONIKER>"
SERVICE_NAME=crescent
# ***

CHAIN_BINARY_URL='https://github.com/b-harvest/game-of-chains/raw/main/crescentd'
CHAIN_BINARY='crescentd'
CHAIN_ID=goc-crescent
PERSISTENT_PEERS="595923e093cbe11dea4f816b48e87691a614a964@34.82.58.71:26656,595923e093cbe11dea4f816b48e87691a614a964@34.145.117.181:26656"

# Install go 1.19.2
echo "Installing go..."
rm go1.19.2.linux-amd64.tar.gz
wget https://go.dev/dl/go1.19.2.linux-amd64.tar.gz
sudo rm -rf /usr/local/go && sudo tar -C /usr/local -xzf go1.19.2.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin

# Install chain binary
echo "Installing crescentd..."
mkdir -p $HOME/go/bin

# Download Linux amd64,
wget $CHAIN_BINARY_URL -O $HOME/go/bin/$CHAIN_BINARY
chmod +x $HOME/go/bin/$CHAIN_BINARY

# or install from source
# echo "Installing build-essential..."
# sudo apt install build-essential -y
# rm -rf crescent
# git clone https://github.com/nodebreaker0-0/crescent
# cd crescent
# git checkout v3.0.0-rc5-ibcv3-ics
# make install

export PATH=$PATH:$HOME/go/bin

# Initialize home directory
echo "Initializing $NODE_HOME..."
rm -rf $NODE_HOME
$CHAIN_BINARY init $NODE_MONIKER --chain-id $CHAIN_ID --home $NODE_HOME

# Replace keys
echo "Replacing keys and genesis file..."
cp $PRIV_VALIDATOR_KEY_FILE $NODE_HOME/config/priv_validator_key.json
cp $NODE_KEY_FILE $NODE_HOME/config/node_key.json

# Reset state
$CHAIN_BINARY tendermint unsafe-reset-all --home $NODE_HOME

sudo rm /etc/systemd/system/$SERVICE_NAME.service
sudo touch /etc/systemd/system/$SERVICE_NAME.service

echo "[Unit]"                               | sudo tee /etc/systemd/system/$SERVICE_NAME.service
echo "Description=crescent service"       | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "After=network-online.target"          | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo ""                                     | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "[Service]"                            | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "User=$USER"                            | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "ExecStart=$HOME/go/bin/$CHAIN_BINARY start --x-crisis-skip-assert-invariants --home $NODE_HOME --p2p.persistent_peers $PERSISTENT_PEERS" | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "Restart=always"                       | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "RestartSec=3"                         | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "LimitNOFILE=4096"                     | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo ""                                     | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "[Install]"                            | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a
echo "WantedBy=multi-user.target"           | sudo tee /etc/systemd/system/$SERVICE_NAME.service -a

# Start service
echo "Starting $SERVICE_NAME.service..."
sudo systemctl daemon-reload

# Add go and gaiad to the path
echo "Setting up paths for go..."
echo "export PATH=$PATH:/usr/local/go/bin" >> .profile

echo "***********************"
echo "After you have updated the genesis file, start the strange service:"
echo "sudo systemctl enable $SERVICE_NAME.service"
echo "sudo systemctl start $SERVICE_NAME.service"
echo ""
echo "And follow the log with:"
echo "journalctl -fu $SERVICE_NAME.service"
echo "***********************"
