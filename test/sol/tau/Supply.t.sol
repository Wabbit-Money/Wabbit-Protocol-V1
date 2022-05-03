//SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.0;

import {SafeMathUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";

import {BaseTAU} from "./BaseTAU.sol";

contract Authorize is BaseTAU {
    using SafeMathUpgradeable for uint256;

    // Test the initial supply
    function testInitialSupply() public {
        assertEq(tau.totalSupply(), _initialSupply);
        assertEq(tau.balanceOf(address(this)), _initialSupply);
    }

    // Test minting and burning
    function testMintBurn() public {
        uint256 initialBalance = _tau.balanceOf(address(this));

        _tau.mint(address(this), mintAmount);
        assertEq(_tau.balanceOf(address(this)), initialBalance.add(mintAmount));

        _tau.burn(address(this), mintAmount);
        assertEq(_tau.balanceOf(address(this)), initialBalance);
    }
}
