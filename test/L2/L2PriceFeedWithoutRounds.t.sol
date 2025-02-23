// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.23;

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { OwnableUpgradeable } from "@openzeppelin-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { Test } from "forge-std/Test.sol";
import { L2PriceFeedWithoutRoundsFactory } from "src/L2/L2PriceFeedWithoutRoundsFactory.sol";
import { L2PriceFeedWithoutRounds } from "src/L2/L2PriceFeedWithoutRounds.sol";

contract L2PriceFeedWithoutRoundsV2Mock is L2PriceFeedWithoutRounds {
    string public testVersion;

    function initializeV2(string memory _version) public reinitializer(2) {
        testVersion = _version;
    }

    function onlyV2() public pure returns (string memory) {
        return "Hello from V2";
    }
}

contract L2PriceFeedWithoutRoundsTest is Test {
    L2PriceFeedWithoutRounds public l2PriceFeed;
    L2PriceFeedWithoutRounds public l2PriceFeedImplementation;

    address public priceFeedAdapter = 0x1038999DCf0A302Cc8Eed72fAeCbf0eEBfC476b0;

    function setUp() public {
        // deploy L2PriceFeedWithoutRoundsFactory Implementation contract
        L2PriceFeedWithoutRoundsFactory l2PriceFeedFactoryImplementation = new L2PriceFeedWithoutRoundsFactory();

        // deploy L2PriceFeedWithoutRoundsFactory contract via Proxy and initialize it at the same time
        L2PriceFeedWithoutRoundsFactory l2PriceFeedFactory;
        l2PriceFeedFactory = L2PriceFeedWithoutRoundsFactory(
            address(
                new ERC1967Proxy(
                    address(l2PriceFeedFactoryImplementation),
                    abi.encodeWithSelector(l2PriceFeedFactory.initialize.selector)
                )
            )
        );

        // create L2PriceFeedWithoutRounds contract
        l2PriceFeed =
            L2PriceFeedWithoutRounds(l2PriceFeedFactory.createL2PriceFeedWithoutRounds("USDT", priceFeedAdapter));
        assert(address(l2PriceFeed) != address(0));
        assertEq(l2PriceFeed.decimals(), 8);
        assertEq(keccak256(bytes(l2PriceFeed.description())), keccak256(bytes("Redstone Price Feed")));
        assertEq(l2PriceFeed.getDataFeedId(), bytes32("USDT"));
        assertEq(address(l2PriceFeed.getPriceFeedAdapter()), priceFeedAdapter);

        // accept ownership
        l2PriceFeed.acceptOwnership();

        // check L2PriceFeedWithoutRoundsFactory variables
        assertEq(l2PriceFeedFactory.l2PriceFeedWithoutRoundsContracts(0), address(l2PriceFeed));
        assertEq(l2PriceFeedFactory.l2PriceFeedWithoutRoundsDataFeedIds(address(l2PriceFeed), 0), "USDT");
    }

    function test_TransferOwnership() public {
        address newOwner = vm.addr(1);

        l2PriceFeed.transferOwnership(newOwner);
        assertEq(l2PriceFeed.owner(), address(this));

        vm.prank(newOwner);
        l2PriceFeed.acceptOwnership();
        assertEq(l2PriceFeed.owner(), newOwner);
    }

    function testFuzz_TransferOwnership_RevertWhenNotCalledByOwner(uint256 _addressSeed) public {
        _addressSeed = bound(_addressSeed, 1, type(uint160).max);
        address nobody = vm.addr(_addressSeed);
        address newOwner = vm.addr(1);

        if (nobody == address(this)) {
            return;
        }

        // owner is this contract
        assertEq(l2PriceFeed.owner(), address(this));

        // address nobody is not the owner so it cannot call transferOwnership
        vm.startPrank(nobody);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nobody));
        l2PriceFeed.transferOwnership(newOwner);
        vm.stopPrank();
    }

    function testFuzz_TransferOwnership_RevertWhenNotCalledByPendingOwner(uint256 _addressSeed) public {
        address newOwner = vm.addr(1);

        l2PriceFeed.transferOwnership(newOwner);
        assertEq(l2PriceFeed.owner(), address(this));

        _addressSeed = bound(_addressSeed, 1, type(uint160).max);
        address nobody = vm.addr(_addressSeed);

        if (nobody == newOwner) {
            return;
        }
        vm.prank(nobody);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nobody));
        l2PriceFeed.acceptOwnership();
    }

    function testFuzz_UpgradeToAndCall_RevertWhenNotOwner(uint256 _addressSeed) public {
        // deploy L2PriceFeedWithoutRoundsV2Mock implementation contract
        L2PriceFeedWithoutRoundsV2Mock l2PriceFeedV2Implementation = new L2PriceFeedWithoutRoundsV2Mock();
        _addressSeed = bound(_addressSeed, 1, type(uint160).max);
        address nobody = vm.addr(_addressSeed);

        if (nobody == address(this)) {
            return;
        }

        vm.prank(nobody);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, nobody));
        l2PriceFeed.upgradeToAndCall(address(l2PriceFeedV2Implementation), "");
    }

    function test_UpgradeToAndCall_SuccessUpgrade() public {
        // deploy L2PriceFeedWithoutRoundsV2Mock implementation contract
        L2PriceFeedWithoutRoundsV2Mock l2PriceFeedV2Implementation = new L2PriceFeedWithoutRoundsV2Mock();

        // upgrade contract, and also change some variables by reinitialize
        l2PriceFeed.upgradeToAndCall(
            address(l2PriceFeedV2Implementation),
            abi.encodeWithSelector(l2PriceFeedV2Implementation.initializeV2.selector, "v2.0.0")
        );

        // wrap L2PriceFeedWithoutRounds proxy with new contract
        L2PriceFeedWithoutRoundsV2Mock l2PriceFeedV2 = L2PriceFeedWithoutRoundsV2Mock(address(l2PriceFeed));

        // check if the upgrade was successful and the variables are the same
        assertEq(l2PriceFeedV2.decimals(), 8);
        assertEq(keccak256(bytes(l2PriceFeedV2.description())), keccak256(bytes("Redstone Price Feed")));
        assertEq(l2PriceFeedV2.getDataFeedId(), bytes32("USDT"));
        assertEq(address(l2PriceFeedV2.getPriceFeedAdapter()), priceFeedAdapter);

        // version of L2PriceFeedWithoutRounds set to v2.0.0
        assertEq(l2PriceFeedV2.testVersion(), "v2.0.0");

        // new function introduced
        assertEq(l2PriceFeedV2.onlyV2(), "Hello from V2");

        // assure cannot re-reinitialize
        vm.expectRevert();
        l2PriceFeedV2.initializeV2("v3.0.0");
    }
}
