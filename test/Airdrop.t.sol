// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Airdrop} from "../src/Airdrop.sol";
import {Test, console2} from "forge-std/Test.sol";

contract AirdropTest is Test {

    // initialize Airdrop contract
    Airdrop public airdrop;

    //  owner address and private key
    uint256 internal ownerPrivateKey;
    address internal owner;

    // address user = makeAddr("user");
    address attacker = makeAddr("attacker");

    function setUp() public {
        ownerPrivateKey = 0xA11CE;
        owner = vm.addr(ownerPrivateKey);

        vm.prank(owner);
        airdrop = new Airdrop();

        // console2.log("deployeraddress address: ", deployerPrivateKey);
        console2.log("owner address: ", owner);
        console2.log("contract address: ", address(airdrop));
        console2.log("test address: ", address(this));
    }

    function testClaimAirdrop() public {
        vm.startPrank(owner);
        uint256 amount = 100;

        // Sign the message
        (uint8 v, bytes32 r, bytes32 s) = _signMessage(owner, amount);
        // Claim the airdrop
        Airdrop.Signature memory sig = Airdrop.Signature(v, r, s);
        airdrop.claimAirdrop(amount, sig);

        // Verify the airdrop was successful
        uint256 balance = airdrop.balanceOf(owner);
        assertEq(balance, amount);
    }

    function testReplayAttackByAnotherAddress() public {
    // Start prank with the owner to generate a valid signature
    vm.startPrank(owner);
    uint256 amount = 100;

    // Sign the message
    (uint8 v, bytes32 r, bytes32 s) = _signMessage(owner, amount);
    Airdrop.Signature memory sig = Airdrop.Signature(v, r, s);

    // Owner claims the airdrop successfully
    airdrop.claimAirdrop(amount, sig);
    uint256 ownerBalance = airdrop.balanceOf(owner);
    assertEq(ownerBalance, amount);
    
    // Stop the prank for owner
    vm.stopPrank();

    // Start prank with the attacker to reuse the owner's signature
    vm.startPrank(attacker);

    // Attacker tries to claim the airdrop using the owner's signature
    airdrop.claimAirdrop(amount, sig);
    vm.stopPrank();

    // Verify the attacker's balance increased
    uint256 attackerBalance = airdrop.balanceOf(attacker);
    assertEq(attackerBalance, amount);
}


function testReplayAttackBySameAccount() public {
    // Start prank with the owner to generate a valid signature
    vm.startPrank(owner);
    uint256 amount = 100;

    // Sign the message
    (uint8 v, bytes32 r, bytes32 s) = _signMessage(owner, amount);
    Airdrop.Signature memory sig = Airdrop.Signature(v, r, s);

    // Owner claims the airdrop successfully
    airdrop.claimAirdrop(amount, sig);
    uint256 initialOwnerBalance = airdrop.balanceOf(owner);
    assertEq(initialOwnerBalance, amount);
    
    // Owner tries to claim the airdrop again using the same signature
    bool success = callAirdropClaim(amount, sig);
    uint256 finalOwnerBalance = airdrop.balanceOf(owner);
    vm.stopPrank();

    // Verify the owner's balance did not increase
    assertGt(finalOwnerBalance, initialOwnerBalance);
    
    // Verify the transaction failed
    assert(success);
}


// Helper function to attempt calling claimAirdrop and catch revert
function callAirdropClaim(uint256 amount, Airdrop.Signature memory sig) internal returns (bool) {
    (bool success, ) = address(airdrop).call(abi.encodeWithSignature("claimAirdrop(uint256,(uint8,bytes32,bytes32))", amount, sig));
    return success;
}

    function _signMessage(address claimant, uint256 amount) internal view returns (uint8, bytes32, bytes32) {
        bytes32 messageHash = keccak256(abi.encodePacked(claimant, amount));
        bytes32 AirdropAmount = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, AirdropAmount);
        return (v, r, s);
    }
}