pragma solidity ^0.4.17;

import "ds-test/test.sol";
import "play-dapp/PLS.sol";
import "./BetGame.sol";

// A contract that can receive and transfer tokens.
// Useful for testing a system with multiple users.
contract TokenUser {
    PLS  token;
    BetGame betGame;

    function TokenUser(PLS token_, BetGame betGame_) {
        token = token_;
        betGame = betGame_;
    }

    function transfer(address _to, uint256 _value,bytes _data) public returns (bool)
    {
        return token.transfer(_to, _value, _data);
    }

    function withdraw()
    {
        betGame.withdraw();
    }
}

contract BetGameTest is DSTest {
    BetGame betGame;
    PLS pls;

    function setUp() public {
        pls = new PLS();
        betGame = new BetGame(address(pls));

        pls.changeController(0x0);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        TokenUser user1 = new TokenUser(pls, betGame);
        TokenUser user2 = new TokenUser(pls, betGame);

        pls.mint(address(user1), 10000);
        pls.mint(address(user2), 10000);

        // with secret 0, false, 13
        // assertEq(betGame.calculateSecretHash(0, false, 13), stringToBytes32("0x6b8f6131d0ac11af070d31278c98837b9929100022656f5e5c357fbbe1692591"));
        // assertEq(betGame.calculateSecretHash(0, false, 13), betGame.calculateSecretHash(0, true, 14));

        // console.log(abi.methodID('startRoundWithFirstBet', [ 'uint256', 'uint256', 'uint256', 'bytes32' ]).toString('hex') + abi.rawEncode([ 'uint256', 'uint256', 'uint256', 'bytes32' ], [ "2", "100", "100", "0xd4c1926f4e6406b47216b65d7b4737d133996f3bfb929bf785d4c29731068268" ]).toString('hex'));
        user1.transfer(address(betGame), 1000, hexStrToBytes("0x21067b3f000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000640000000000000000000000000000000000000000000000000000000000000064d4c1926f4e6406b47216b65d7b4737d133996f3bfb929bf785d4c29731068268"));

        assertEq(betGame.roundCount(), 2);
        assertEq(betGame.betCount(), 1);

        // with secret 0, true, 14
        // console.log(abi.methodID('betWithRound', [ 'uint256', 'bytes32' ]).toString('hex') + abi.rawEncode([ 'uint256', 'bytes32' ], [ "1", "0xf90ae7e1cc996f1b334ff1e3411f0fdbc47abc8b9d65f3d9f91e9a3c14b8b979" ]).toString('hex'));
        user2.transfer(address(betGame), 1000, hexStrToBytes("0x38b9ef9c0000000000000000000000000000000000000000000000000000000000000001f90ae7e1cc996f1b334ff1e3411f0fdbc47abc8b9d65f3d9f91e9a3c14b8b979"));
        
        assertEq(betGame.betCount(), 2);

        assertTrue(betGame.revealBet(0, 0, false, 13));

        assertTrue(betGame.revealBet(1, 0, true, 14));

        assertTrue(betGame.betRevealed(1));

        betGame.finalizeRound(1);

        assertEq(pls.balanceOf(address(user1)), 9000);
        assertEq(pls.balanceOf(address(user2)), 9000);

        user1.withdraw();
        user2.withdraw();

        // user2 win the game...
        assertEq(pls.balanceOf(address(user1)), 9000);
        assertEq(pls.balanceOf(address(user2)), 11000);

        // assertEq(block.number, 0);

        // assertEq(betGame.fallbackFrom(), address(this));
        // assertEq(betGame.fallbackValue(), 100);

        
    }

    function stringToBytes32(string memory source) returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    function hexStrToBytes(string hex_str) constant returns (bytes)
    {
        //Check hex string is valid
        if (bytes(hex_str)[0]!='0' ||
            bytes(hex_str)[1]!='x' ||
            bytes(hex_str).length%2!=0 ||
            bytes(hex_str).length<4)
            {
                throw;
            }

        bytes memory bytes_array = new bytes((bytes(hex_str).length-2)/2);

        for (uint i=2;i<bytes(hex_str).length;i+=2)
        {
            uint tetrad1=16;
            uint tetrad2=16;

            //left digit
            if (uint(bytes(hex_str)[i])>=48 &&uint(bytes(hex_str)[i])<=57)
                tetrad1=uint(bytes(hex_str)[i])-48;

            //right digit
            if (uint(bytes(hex_str)[i+1])>=48 &&uint(bytes(hex_str)[i+1])<=57)
                tetrad2=uint(bytes(hex_str)[i+1])-48;

            //left A->F
            if (uint(bytes(hex_str)[i])>=65 &&uint(bytes(hex_str)[i])<=70)
                tetrad1=uint(bytes(hex_str)[i])-65+10;

            //right A->F
            if (uint(bytes(hex_str)[i+1])>=65 &&uint(bytes(hex_str)[i+1])<=70)
                tetrad2=uint(bytes(hex_str)[i+1])-65+10;

            //left a->f
            if (uint(bytes(hex_str)[i])>=97 &&uint(bytes(hex_str)[i])<=102)
                tetrad1=uint(bytes(hex_str)[i])-97+10;

            //right a->f
            if (uint(bytes(hex_str)[i+1])>=97 &&uint(bytes(hex_str)[i+1])<=102)
                tetrad2=uint(bytes(hex_str)[i+1])-97+10;

            //Check all symbols are allowed
            if (tetrad1==16 || tetrad2==16)
                throw;

            bytes_array[i/2-1]=byte(16*tetrad1+tetrad2);
        }

        return bytes_array;
    }


}
