# Rules of Bet Game

Bet Game is seperated to a list of rounds, for every round, every player will join in by putting an bet here, the contract will automaticly calculate a game result according to the secret of these bets, which is an odd or an even, according the sum of the secrets of the bets. Every player will get reward according to their guess settings in the origin bet, they will win and get reward  if they guess the right answer, otherwise they will lose.

Every one can trigger the round finalization action once all bets are fullfilled and all bets are revealed. But if someone forget to reveal the bet in specific time(there will one round parameter controlling this: _maxRevealBlockCount), the round will fail to reveal, the funds of the players who revealed will be returned back, but the funds of players who didn't reveal in time will be punished and be confiscated to the finalizer and contract owner.

There are some impoort parameters need to set:

1. The total "betCount" that will happen in the round, which means the how many bets should be played for this round. The player who start a new round(room),and join with his bet can use "startRoundWithFirstBet". The suggested betCount for easy to find counter-party player, is just 2.

2. The parameters of one round includes:

    a. _betCount, the count of the bets.

    b. _maxBetBlockCount, the max waiting bet count till finalizing the round, that is, anyone can finalize the round after "_maxBetBlockCount" from the first bet.

    c. _maxRevealBlockCount, not implemented, supposed to be the max waiting reveal block count till finalizing the round, that is, anyone can finalize the round after "_maxRevealBlockCount" from the last bet block.

    d. _secretHashForFirstBet, this is the hash of the guess and secret setted by the player, which is also the result of "calculateSecretHash(uint _nonce, bool _guessOdd, bytes32 _secret)", the "nonce" here is just a random number. The "_guessOdd" 

3. After some round are created, other players can join that room, and fullfill one of the left bets positions with their guess and secret settings.

4. After all the bet positions are fullfilled by the players, then the process of secret revealing begins. Every player of bets in this round are required to reveal their bets. The bet secrets(nonce, guess, secret) are actrully stored in user's end browers. so they just click the reveal to send transactions.

5. After all the bet are revealed (in revealed status), then any player or any one can trigger to finalize the round to see the result to check whether they win or not. But if the bet are not revealed and the block of (_maxRevealBlockCount) arrived, any one can trigger to cancel this round, players who revealed their bets will get refunded, but those who didn't will lose their funds.

6. The round ends.

# 游戏规则

対猜游戏分为一系列轮次，每一轮玩家将通过在提交Bet来加入，合约将根据这些Bet的秘密（自动计算一个奇数或偶数）自动计算游戏结果，即Bet秘诀的总和。每个玩家都会根据他们在原始Bet中的猜测设置获得奖励，如果他们猜出正确的答案，他们将赢得奖励，否则他们将会输。

一旦所有Bet全部被填满并且所有Bet的秘密都被揭开来，每个人都可以触发并打开这一轮的结果。但是如果有人忘记在特定的时间内揭开bet（每一轮次有一个参数控制这个：_maxRevealBlockCount），那么这个回合将不会打开有结果，显示的玩家的资金将被退回，但是没有揭开秘密的玩家的资金将被处罚，并被没收给打开者和合约所有者。

每一轮次有一些的参数需要设置：

1. 本轮将发生的总计“Bet”个数，这意味着本轮应有多少次Bet。开始新一轮（房间）并参与其投注的玩家可以使用“startRoundWithFirstBet”。建议betCount容易找到对方球员，只有2。

2. 一轮参数包括:

    a. _betCount，bets的个数或席位个数。

    b. _maxBetBlockCount，最大等待bet数直到最后一轮，也就是说，任何人都可以在第一次bet之后的“_maxBetBlockCount”之后完成回合。

    C. _maxRevealBlockCount，没有实现，应该是最后的等待显示块数，直到最后一轮，也就是说，任何人都可以在最后一个bet块的“_maxRevealBlockCount”之后确定一轮。

    d. _secretHashForFirstBet，这是由玩家设置的猜测和秘密的散列，这也是“calculateSecretHash（uint _nonce，bool _guessOdd，bytes32_secret）”的结果，“nonce”在这里只是一个随机数。 “_guessOdd”

3. 创建一轮之后，其他玩家可以加入该房间，并使用猜测和秘密设置完成其中一个bet席位。

4. 所有bet在玩家填满后，秘密揭示的过程就开始了。每一位本轮投注的玩家都必须透露他们的投注。投注秘密（随机数，猜测，秘密）被存储在用户的最终浏览器中。所以他们只需点击揭示发送交易。

5.在所有的bet被揭示（处于显示状态）之后，任何玩家或任何人都可以触发确定该回合以查看结果以检查他们是否赢。但是，如果没有揭开bet的秘密，并且（_maxRevealBlockCount）块被触发，任何人都可以触发让这一轮终结取消，显示他们投注的玩家将得到退回，但没有揭开bet秘密的人将会失去资金。

6.这一轮结束。