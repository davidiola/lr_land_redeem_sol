pragma solidity 0.6.12;

contract SomeAccount {
    // Make contract payable to receive funds
    event Received(address, uint);
    receive() external payable {
        emit Received(msg.sender, msg.value);
    }
}