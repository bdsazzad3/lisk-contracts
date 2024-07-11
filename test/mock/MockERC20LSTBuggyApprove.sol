// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @title MockERC20LSTBuggyApprove
/// @notice MockERC20LSTBuggyApprove is a mock implementation of ERC20 token which also mimics LST functionalities
///         by automatically sending back newly minted tokens upon receiving ETH.
///         The contract 'approve' function always returns 'false' for testing purposes.
contract MockERC20LSTBuggyApprove is ERC20 {
    /// @notice the conversion rate between 1 * ETH and the ERC20 token.
    ///         A 1-to-1 conversion corresponds to tokensPerETH = 1e18.
    uint256 private tokensPerETH;

    constructor(uint256 _tokensPerETH) ERC20("Mock LST Token", "mLST") {
        tokensPerETH = _tokensPerETH;
    }

    /// @notice Shortcut function to convert ETH to ERC20 token.
    receive() external payable {
        uint256 amount = msg.value * tokensPerETH / 1e18;
        _mint(msg.sender, amount);
    }

    function approve(address spender, uint256 value) public override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, value);
        return false;
    }
}
