if [ $# -lt 1 ]
then
	echo "usage: $0 rmv"
	exit 1
fi

rmv=$1

if [ $rmv == true ]
then
	forge remove OpenZeppelin/openzeppelin-contracts
	forge remove dapphub/ds-test
  forge remove aave/protocol-v2
	forge remove foundry-rs/forge-std
fi

forge install OpenZeppelin/openzeppelin-contracts@v4.5.0
forge install dapphub/ds-test@2c7dbcc8586b33f358e3307a443e524490c17666
forge install aave/protocol-v2@61c2273a992f655c6d3e7d716a0c2f1b97a55a92
forge install foundry-rs/forge-std@v0.1.0
