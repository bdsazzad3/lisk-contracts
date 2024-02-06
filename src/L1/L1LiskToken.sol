// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.23;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC20Burnable } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import { ERC20Permit } from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import { AccessControl } from "@openzeppelin/contracts/access/AccessControl.sol";

/// @title L1LiskToken
/// @notice L1LiskToken is an implementation of ERC20 token and is an extension of AccessControl, ERC20Permit and
///         ERC20Burnable token contracts. It maintains the ownership of the deployed contract and only allows the
///         owners to transfer the ownership. The L1LiskToken exclusively authorizes burners to reduce the total supply,
///         while the management of burner accounts is solely under the domain of the owner.
contract L1LiskToken is ERC20Burnable, AccessControl, ERC20Permit {
    /// @notice Name of the token.
    string private constant NAME = "Lisk";

    /// @notice Symbol of the token.
    string private constant SYMBOL = "LSK";

    /// @notice Total supply of the token.
    uint256 private constant TOTAL_SUPPLY = 300_000_000 * 10 ** 18; //300 million LSK tokens

    /// @notice A unique role identifier for accounts with the ability to burn tokens.
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    /// @notice Constructs the L1LiskToken contract.
    constructor() ERC20(NAME, SYMBOL) ERC20Permit(NAME) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _mint(msg.sender, TOTAL_SUPPLY);
    }

    /// @notice Transfer the contract ownership to a new account.
    /// @param account The address of the new owner.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function transferOwnership(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(DEFAULT_ADMIN_ROLE, account);
        _revokeRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    /// @notice Check if an account has the burner role.
    /// @param account The account to check.
    /// @return True if the account has the burner role, false otherwise.
    function isBurner(address account) public view returns (bool) {
        return hasRole(BURNER_ROLE, account);
    }

    /// @notice Assign the burner role to an account.
    /// @param account The account to be assigned the burner role.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function addBurner(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(BURNER_ROLE, account);
    }

    /// @notice Remove the burner role from an account.
    /// @param account The account to remove the burner role from.
    /// @dev Requires DEFAULT_ADMIN_ROLE.
    function renounceBurner(address account) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(BURNER_ROLE, account);
    }

    /// @notice Burn tokens from the caller's account.
    /// @param value The amount of tokens to burn.
    /// @dev Requires BURNER_ROLE.
    function burn(uint256 value) public override onlyRole(BURNER_ROLE) {
        super.burn(value);
    }

    /// @notice Burn tokens from another account, deducting from the caller's allowance.
    /// @param account The account to burn tokens from.
    /// @param value   The amount of tokens to be burned.
    /// @dev Requires BURNER_ROLE.
    function burnFrom(address account, uint256 value) public override onlyRole(BURNER_ROLE) {
        super.burnFrom(account, value);
    }
}