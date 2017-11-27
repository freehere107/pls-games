pragma solidity ^0.4.17;

import "ds-test/test.sol";

import "./PlsGames.sol";

contract PlsGamesTest is DSTest {
    PlsGames games;

    function setUp() public {
        games = new PlsGames();
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }
}
