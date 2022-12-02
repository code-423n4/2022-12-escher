// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Escher} from "src/Escher.sol";
import "openzeppelin/token/ERC1155/utils/ERC1155Holder.sol";

contract EscherTest is Test, ERC1155Holder {
    Escher public escher;

    bytes32 public constant CREATOR_ROLE = keccak256("CREATOR_ROLE");
    bytes32 public constant CURATOR_ROLE = keccak256("CURATOR_ROLE");

    address public creator = address(1);
    address public curator = address(2);

    function setUp() public virtual {
        escher = new Escher();
        escher.grantRole(CURATOR_ROLE, address(this));
        escher.addCreator(address(this));
    }

    function test_Admin_AddCreator() public {
        escher.addCreator(creator);
        assertTrue(escher.hasRole(CREATOR_ROLE, creator));
    }

    function test_Admin_GrantCurator() public {
        escher.grantRole(CURATOR_ROLE, curator);
        assertTrue(escher.hasRole(CURATOR_ROLE, curator));
    }

    function test_Curator_AddCreator() public {
        test_Admin_GrantCurator();
        vm.prank(curator);
        escher.addCreator(creator);
        assertTrue(escher.hasRole(CREATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CREATOR_ROLE)), 1);
    }

    function test_Curator_AddSelf() public {
        test_Admin_GrantCurator();

        vm.prank(curator);
        escher.addCreator(curator);
        assertTrue(escher.hasRole(CREATOR_ROLE, curator));
    }

    function test_Curator_AddCreatorTwice() public {
        test_Curator_AddSelf();

        vm.prank(curator);
        vm.expectRevert();
        escher.addCreator(curator);
        assertTrue(escher.hasRole(CREATOR_ROLE, curator));
        assertEq(escher.balanceOf(curator, uint256(CREATOR_ROLE)), 1);
    }

    function test_RevertsWhenCurator_GrantCurator() public {
        test_Admin_GrantCurator();

        vm.prank(curator);
        vm.expectRevert();
        escher.grantRole(CURATOR_ROLE, creator);
        assertFalse(escher.hasRole(CURATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CURATOR_ROLE)), 0);
    }

    function test_RevertWhenNotCuratorOrAdmin_GrantRoleCreator() public {
        vm.prank(curator);
        vm.expectRevert();
        escher.grantRole(CREATOR_ROLE, creator);
        assertFalse(escher.hasRole(CREATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CREATOR_ROLE)), 0);
    }

    function test_RevertWhenNotCuratorOrAdmin_AddCreator() public {
        test_Admin_GrantCurator();

        vm.prank(creator);
        vm.expectRevert();
        escher.addCreator(creator);
        assertFalse(escher.hasRole(CREATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CREATOR_ROLE)), 0);
    }

    function test_Admin_RevokeRoleCurator() public {
        test_Admin_GrantCurator();

        escher.revokeRole(CURATOR_ROLE, curator);
        assertFalse(escher.hasRole(CURATOR_ROLE, curator));
        assertEq(escher.balanceOf(curator, uint256(CURATOR_ROLE)), 0);
    }

    function test_Admin_RevokeRoleCreator() public {
        test_Admin_AddCreator();

        escher.revokeRole(CREATOR_ROLE, creator);
        assertFalse(escher.hasRole(CREATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CREATOR_ROLE)), 0);
    }

    function test_Creator_RenounceCreator() public {
        test_Admin_AddCreator();
        assertTrue(escher.hasRole(CREATOR_ROLE, creator));

        vm.prank(creator);
        escher.renounceRole(CREATOR_ROLE, creator);
        assertFalse(escher.hasRole(CREATOR_ROLE, creator));
        assertEq(escher.balanceOf(creator, uint256(CREATOR_ROLE)), 0);
    }

    function test_Curator_RenounceCurator() public {
        test_Admin_GrantCurator();
        assertTrue(escher.hasRole(CURATOR_ROLE, curator));

        vm.prank(curator);
        escher.renounceRole(CURATOR_ROLE, curator);
        assertFalse(escher.hasRole(CURATOR_ROLE, curator));
        assertEq(escher.balanceOf(curator, uint256(CURATOR_ROLE)), 0);
    }

    function test_RevertsWhenSoulBound_safeTransferFrom() public {
        vm.expectRevert("SoulBound");
        escher.safeTransferFrom(address(this), curator, uint256(CREATOR_ROLE), 1, "");
        assertEq(escher.balanceOf(address(this), uint256(CREATOR_ROLE)), 1);
        assertEq(escher.balanceOf(curator, uint256(CREATOR_ROLE)), 0);
    }

    function test_RevertsWhenSoulBound_safeBatchTransferFrom() public {
        uint256[] memory ids = new uint256[](1);
        uint256[] memory amounts = new uint256[](1);
        ids[0] = uint256(CREATOR_ROLE);
        amounts[0] = 1;
        vm.expectRevert("SoulBound");
        escher.safeBatchTransferFrom(address(this), curator, ids, amounts, "");
        assertEq(escher.balanceOf(address(this), uint256(CREATOR_ROLE)), 1);
        assertEq(escher.balanceOf(curator, uint256(CREATOR_ROLE)), 0);
    }
}
