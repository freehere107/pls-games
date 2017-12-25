pragma solidity ^0.4.13;

import "ds-stop/stop.sol";
import "play-dapp/PLS.sol";
import "./SafeMath.sol";

contract BetGame is DSStop {
    using SafeMath for uint256;

    struct Bet {
        // player
        address player;
        bytes32 secretHash;
        uint256 amount;
        uint roundId;

        // flag
        bool isRevealed;

        // reveal time
        uint nonce;
        bool guessOdd;
        bytes32 secret;
    }

    struct Round {
        uint betCount;
        uint maxBetBlockCount;      // Max Block Count for wating others to join betting, will return funds if no enough bets join in.
        uint maxRevealBlockCount;   // Should have enough minimal blocks e.g. >100

        uint[] betIds;

        uint startBetBlock;
        uint startRevealBlock;

        uint finalizedBlock;
    }

    uint public betCount;
    uint public roundCount;

    mapping(uint => Bet) public bets;
    mapping(uint => Round) public rounds;
    mapping(address => uint) public balancesForWithdraw;

    uint public poolAmount;

    uint256 public initializeTime;

    PLS public pls;

    struct TokenMessage {
        bool init;
        address fallbackFrom;
        uint256 fallbackValue;
    }

    TokenMessage public tokenMsg;

    modifier notNull(address _address) {
        if (_address == 0)
            throw;
        _;
    }

    modifier tokenPayable {
        require(msg.sender == address(this));
        require(tokenMsg.init);

        _;
    }

    function BetGame(address _pls)
    {
        initializeTime = now;
        roundCount = 1;

        pls = PLS(_pls);
    }

    function receiveToken(address from, uint256 _amount, address _token) public
    {
        // do nothing.
    }

    function tokenFallback(address _from, uint256 _value, bytes _data) public
    {
        require(msg.sender == address(pls));
        tokenMsg.init = true;
        tokenMsg.fallbackFrom = _from;
        tokenMsg.fallbackValue = _value;

        if(! this.call(_data)){
            revert();
        }

        tokenMsg.init = false;
        tokenMsg.fallbackFrom = 0x0;
        tokenMsg.fallbackValue = 0;
    }
    
    function startRoundWithFirstBet(uint _betCount, uint _maxBetBlockCount, uint _maxRevealBlockCount, bytes32 _secretHashForFirstBet) public tokenPayable returns (uint roundId)
    {
        require(_betCount >= 2);
        require(_maxBetBlockCount >= 100);
        require(_maxRevealBlockCount >= 100);

        require(tokenMsg.fallbackValue > 0);

        uint betId = addBet(tokenMsg.fallbackFrom, _secretHashForFirstBet, tokenMsg.fallbackValue);

        roundId = addRound(_betCount, _maxBetBlockCount, _maxRevealBlockCount, betId);
    }

    function isPlayerInRound(uint _roundId, address _player) public constant returns (bool isIn)
    {
        for (uint i=0; i < rounds[_roundId].betIds.length; i++) {
            if (bets[rounds[_roundId].betIds[i]].player == _player)
            {
                isIn = true;
                return;
            }  
        }

        isIn = false;
    }

    function betWithRound(uint _roundId, bytes32 _secretHashForBet) public tokenPayable
    {
        require(tokenMsg.fallbackValue > 0);
        require(rounds[_roundId].finalizedBlock == 0);
        require(rounds[_roundId].betIds.length < rounds[_roundId].betCount);
        require(!isPlayerInRound(_roundId, tokenMsg.fallbackFrom));

        uint betId = addBet(tokenMsg.fallbackFrom, _secretHashForBet, tokenMsg.fallbackValue);
        rounds[_roundId].betIds.push(betId);
        bets[betId].roundId = _roundId;

        if (rounds[_roundId].betIds.length == rounds[_roundId].betCount)
        {
            rounds[_roundId].startRevealBlock = getBlockNumber();
        }
    }

    function revealBet(uint betId, uint _nonce, bool _guessOdd, bytes32 _secret) public returns (bool)
    {
        Bet bet = bets[betId];
        Round round = rounds[bet.roundId];
        require(round.betIds.length == round.betCount);
        require(round.finalizedBlock == 0);

        if (bet.secretHash == keccak256(_nonce, _guessOdd, _secret) )
        {
            bet.isRevealed = true;
            bet.nonce = _nonce;
            bet.guessOdd = _guessOdd;
            bet.secret = _secret;
            
            return true;
        }
        
        return false;
    }

    // anyone can try to finalize after the max block count or bets in the round are all revealed.
    function finalizeRound(uint roundId) public
    {
        require(rounds[roundId].finalizedBlock == 0);

        uint finalizedBlock = getBlockNumber();
        
        uint i = 0;
        Bet bet;
        
        if (rounds[roundId].betIds.length < rounds[roundId].betCount && finalizedBlock.sub(rounds[roundId].startBetBlock) > rounds[roundId].maxBetBlockCount)
        {
            // betting timeout
            // return funds to players

            for (i=0; i<rounds[roundId].betIds.length; i++) {
                bet = bets[rounds[roundId].betIds[i]];
                balancesForWithdraw[bet.player] = balancesForWithdraw[bet.player].add(bet.amount);
            }

            rounds[roundId].finalizedBlock = finalizedBlock;
            return;
        } else if (rounds[roundId].betIds.length == rounds[roundId].betCount) {
            assert( calculateJackpotInFinalize(roundId) );

            rounds[roundId].finalizedBlock = finalizedBlock;
        } else
        {
            throw;
        }
    }

    function withdraw() public returns (bool)
    {
        var amount = balancesForWithdraw[msg.sender];
        if (amount > 0) {
            balancesForWithdraw[msg.sender] = 0;

            if (!pls.transfer(msg.sender, amount)) {
                // No need to call throw here, just reset the amount owing
                balancesForWithdraw[msg.sender] = amount;
                return false;
            }
        }
        return true;
    }

    function claimFromPool() public auth
    {
        owner.transfer(poolAmount);
        ClaimFromPool();
    }

    /*
     * Constant functions
     */
    // For players to calculate hash of secret before start a bet.
    function calculateSecretHash(uint _nonce, bool _guessOdd, bytes32 _secret) constant public returns (bytes32 secretHash)
    {
        secretHash = keccak256(_nonce, _guessOdd, _secret);
    }
    
    function getBetIds(uint roundIndex) public constant returns (uint[] _betIds)
    {
        _betIds = new uint[](rounds[roundIndex].betIds.length);

        for (uint i=0; i < rounds[roundIndex].betIds.length; i++)
            _betIds[i] = rounds[roundIndex].betIds[i];
    }

    function getBetIdAtRound(uint roundIndex, uint innerIndex) constant public returns (uint) {
        return rounds[roundIndex].betIds[innerIndex];
    }

    function getBetSizeAtRound(uint roundIndex) constant public returns (uint) {
        return rounds[roundIndex].betIds.length;
    }

    /*
     * Internal functions
     */
    /// @dev Adds a new bet to the bet mapping, if bet does not exist yet.
    /// @param _player The player of the bet.
    /// @param _secretHash The hash of the nonce, guessOdd, and secret for the bet, hash ＝ keccak256(_num, _guessOdd, _secret) 
    /// @param _amount The amount of the bet.
    /// @return Returns bet ID.
    function addBet(address _player, bytes32 _secretHash, uint256 _amount)
        internal
        notNull(_player)
        returns (uint betId)
    {
        betId = betCount;
        bets[betId] = Bet({
            player: _player,
            secretHash: _secretHash,
            amount: _amount,
            roundId: 0,
            isRevealed: false,
            nonce:0,
            guessOdd:false,
            secret: ""
        });
        betCount += 1;
        BetSubmission(betId);
    }

    function addRound(uint _betCount, uint _maxBetBlockCount, uint _maxRevealBlockCount, uint _betId)
        internal
        returns (uint roundId)
    {
        roundId = roundCount;
        rounds[roundId].betCount = _betCount;
        rounds[roundId].maxBetBlockCount = _maxBetBlockCount;
        rounds[roundId].maxRevealBlockCount = _maxRevealBlockCount;
        rounds[roundId].betIds.push(_betId);
        rounds[roundId].startBetBlock = getBlockNumber();
        rounds[roundId].startRevealBlock = 0;
        rounds[roundId].finalizedBlock = 0;

        bets[_betId].roundId = roundId;

        roundCount += 1;
        RoundSubmission(roundId);
    }
    
    function betRevealed(uint roundId) constant public returns(bool)
    {
        bool betsRevealed = true;
        uint i = 0;
        Bet bet;
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            bet = bets[rounds[roundId].betIds[i]];
            if (!bet.isRevealed)
            {
                betsRevealed = false;
                break;
            }
        }
        
        return betsRevealed;
    }
    
    function getJackpotResults(uint roundId) constant public returns(uint, uint, bool)
    {
        uint jackpotSum;
        uint jackpotNum;

        uint oddCount;
        uint oddSum;

        uint i = 0;
        
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            jackpotSum = jackpotSum.add(bets[rounds[roundId].betIds[i]].amount);
            jackpotNum = jackpotNum.add(uint(bets[rounds[roundId].betIds[i]].secret));
            
            if(bets[rounds[roundId].betIds[i]].guessOdd){
                oddCount++;
                oddSum = oddSum.add(bets[rounds[roundId].betIds[i]].amount);
            }
        }
        
        bool isOddWin = (jackpotNum % 2 == 1) ? true : false;
        // uint winnerNumber = isOddWin ? oddCount: evenCount;

        if (oddCount == 0 || oddCount == rounds[roundId].betIds.length)
        {
            // winnerNumber = oddCount > 0 ? oddCount : evenCount;
            isOddWin = oddCount > 0 ? true : false;
        }
        
        return (jackpotSum, oddSum, isOddWin);
    }
    
    function updateRewardForBet(uint betId, bool isOddWin, uint jackpotSum, uint oddSum, uint evenSum, uint dustLeft) internal returns(uint)
    {
        uint reward = 0;
        if (isOddWin && bets[betId].guessOdd)
        {
            reward = bets[betId].amount.mul(jackpotSum).div(oddSum);
            balancesForWithdraw[bets[betId].player] = balancesForWithdraw[bets[betId].player].add(reward);
            dustLeft = dustLeft.sub(reward);
        } else if (!isOddWin && !bets[betId].guessOdd)
        {
            reward = bets[betId].amount.mul(jackpotSum).div(evenSum);
            balancesForWithdraw[bets[betId].player] = balancesForWithdraw[bets[betId].player].add(reward);
            dustLeft = dustLeft.sub(reward);
        }
        
        return dustLeft;
    }
    
    function updateJackpotRewards(uint roundId) internal returns (uint dustLeft)
    {
        var (jackpotSum, oddSum, isOddWin) = getJackpotResults(roundId);

        dustLeft = jackpotSum;
        uint i = 0;
        
        for (i=0; i<rounds[roundId].betIds.length; i++) {
            dustLeft = updateRewardForBet(rounds[roundId].betIds[i], isOddWin, jackpotSum, oddSum, jackpotSum - oddSum, dustLeft);
        }
    }

    function calculateJackpotInFinalize(uint roundId) internal returns (bool)
    {
        uint finalizedBlock = getBlockNumber();
        
        bool betsRevealed = betRevealed(roundId);

        if (betsRevealed)
        {
            uint dustLeft = updateJackpotRewards(roundId);

            poolAmount = poolAmount.add(dustLeft);

            
            return true;
        }
        else if (!betsRevealed && finalizedBlock.sub(rounds[roundId].startRevealBlock) > rounds[roundId].maxRevealBlockCount)
        {
            // return funds to players who have already revealed
            // but for those who didn't reveal, the funds go to pool
            // revealing timeout
            uint i = 0;
            for (i=0; i<rounds[roundId].betIds.length; i++) {
                if (bets[rounds[roundId].betIds[i]].isRevealed)
                {
                    balancesForWithdraw[bets[rounds[roundId].betIds[i]].player] = balancesForWithdraw[bets[rounds[roundId].betIds[i]].player].add(bets[rounds[roundId].betIds[i]].amount);
                } else
                {
                    // go to pool
                    poolAmount = poolAmount.add(bets[rounds[roundId].betIds[i]].amount);
                }
            }

            return true;
        } else{
            return false;
        }
    }

    /// @notice This function is overridden by the test Mocks.
    function getBlockNumber() internal constant returns (uint256) {
        return block.number;
    }

    event BetSubmission(uint indexed _betId);
    event RoundSubmission(uint indexed _roundId);

    event ClaimFromPool();
}