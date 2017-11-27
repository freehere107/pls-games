pragma solidity ^0.4.17;

import "ds-test/test.sol";

import "./BetGame.sol";

contract BetGameTest is DSTest {
    BetGame betGame;
    PLS pls;

    function setUp() public {
        pls = new PLS();
        betGame = new BetGame(address(pls));
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
