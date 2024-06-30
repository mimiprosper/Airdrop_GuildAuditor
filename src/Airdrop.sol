// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

contract Airdrop {
    mapping(address => uint256) public balances;
    address public owner;

    struct Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
    }

    constructor() {
        owner = msg.sender;
    }

    // function to claim an airdrop
    function claimAirdrop(uint256 amount, Signature memory sig) public {
        require(verifySignature(amount, sig), "Invalid signature");

        balances[msg.sender] += amount;
    }

    function verifySignature(uint256 amount, Signature memory sig) public pure returns (bool) {
        bytes32 messageHash = keccak256(abi.encodePacked(amount));
        bytes32 ethSignedMessageHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address signer = ecrecover(ethSignedMessageHash, sig.v, sig.r, sig.s);
        return signer != address(0);
    }

    // Function to get the balance of a particular address
    function balanceOf(address _addr) public view returns (uint256) {
        return balances[_addr];
    }
}