'use strict'
var abi = require('ethereumjs-abi')
var Web3 = require('web3')
if (typeof $ == 'undefined' && typeof require === 'function') {
  var $ = require('jquery')
}
class Pls {
  constructor(web3url, contractAddr, contractABI, tokenAddr, tokenABI) {
    if (!web3url) {
      web3url = 'http://localhost:8545'
    }
    if (typeof web3 !== 'undefined')
      this.web3 = new Web3(web3.currentProvider)
    else
      this.web3 = new Web3(new Web3.providers.HttpProvider(web3url))
    this.contract = new this.web3.eth.Contract(contractABI, contractAddr)
    this.token = new this.web3.eth.Contract(tokenABI, tokenAddr)
    this.decimals = 18
    this.secret = this.web3.utils.utf8ToHex('ethereum')
  }

  encodeHex(str, zPadLength) {
    if (typeof str === 'number') {
      str = str.toString(16)
    } else {
      str = [...str].map((char) =>
        char.charCodeAt(0).toString(16).padStart(2, '0'))
        .join('')
    }
    return str.padStart(zPadLength, '0')
  }

  SecretHash(account, guess, secret, nonce, callback) {
    console.log('SecretHash', nonce, guess, this.web3.utils.utf8ToHex('secret'))
    return this.contract.methods.calculateSecretHash(nonce, guess, this.web3.utils.utf8ToHex(secret)).call({from: account}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(null, info)

    })
  }

  abiHash(round_id, func, hash, callback) {
    let calResult = ''
    if (func === 'betWithRound') {
      calResult = abi.methodID('betWithRound', ['uint256', 'bytes32']).toString('hex') +
        abi.rawEncode(['uint256', 'bytes32'], [`${round_id}`, hash]).toString('hex')
    } else {
      calResult = abi.methodID('startRoundWithFirstBet', ['uint256', 'uint256', 'uint256', 'bytes32']).toString('hex') +
        abi.rawEncode(['uint256', 'uint256', 'uint256', 'bytes32'], ["2", "100", "100", hash]).toString('hex')
    }
    return callback(null, calResult)
  }


  num2bal(value) {
    return Math.floor(value * Math.pow(10, this.decimals))
  }

  bal2num(bal) {
    return bal && bal.div ?
      bal.div(Math.pow(10, this.decimals)) :
      bal / Math.pow(10, this.decimals)
  }

  getAccounts(callback) {
    return this.web3.eth.getAccounts(callback)
  }

  getTokenInfo(account, callback) {
    this.token.methods.balanceOf(account).call((err, balance) => {
      if (err) {
        return callback(err, null)
      }
      return callback(null, {'name': 'PLS', 'symbol': 'PLS', 'decimals': 18, balance: this.bal2num(balance)})
    });
  }

  doBet(account, deposit, hexStrToBytes, callback) {
    deposit = this.web3.utils.toWei(`${deposit}`, "ether")
    return this.token.methods.balanceOf(account).call({from: account}, (err, balance) => {
      if (err) {
        return callback(err)
      } else if (!(balance >= deposit)) {
        return callback(new Error(`Not enough tokens.Token balance = ${this.bal2num(balance)}, required = ${this.bal2num(deposit)}`))
      }
      return this.token.methods['transfer(address,uint256,bytes)'](this.contract.options.address, deposit, hexStrToBytes).send({
        from: account,
        gas: 600000,
        // gasPrice: '20000000000'
      })
        .on('transactionHash', function (hash) {
        })
        .on('receipt', function (receipt) {
        })
        .on('confirmation', function (confirmationNumber, receipt) {
          if (confirmationNumber >= 10) {
            return callback(null, receipt)
          }
        })
        .on('error', console.error)
        .then(function () {
          return callback(null, null)
        })
    })
  }

  mintToken(account, to, deposit, callback) {//token mint
    return this.token.methods.mint(to, this.web3.utils.toWei(`${deposit}`, "ether")).send({from: account})
      .on('transactionHash', function (hash) {
      })
      .on('receipt', function (receipt) {
      })
      .on('confirmation', function (confirmationNumber, receipt) {
        if (confirmationNumber >= 10) {
          return callback(null, receipt)
        }
      })
      .on('error', console.error)
      .then(function () {
        return callback(null, null)
      })
  }

  transToken(account, to, deposit, callback) {//token mint
    return this.token.methods.transferFrom(account, to, this.web3.utils.toWei(`${deposit}`, "ether")).send({from: account})
      .on('transactionHash', function (hash) {
      })
      .on('receipt', function (receipt) {
      })
      .on('confirmation', function (confirmationNumber, receipt) {
        if (confirmationNumber >= 10) {
          return callback(null, receipt)
        }
      })
      .on('error', console.error)
      .then(function () {
        return callback(null, null)
      })
  }


  getRoundCount(account, callback) {
    return this.contract.methods.roundCount().call({from: account}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(null, info)
    })
  }


  getBetCount(account, callback) {
    return this.contract.methods.betCount().call({from: account}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(null, info)
    })
  }

  settleBet(roundId, account, callback) {
    return this.contract.methods.finalizeRound(roundId).send({from: account})
      .on('confirmation', function (confirmationNumber, receipt) {
        if (confirmationNumber >= 5) {
          return callback(null, receipt)
        }
      })
      .on('error', console.error)
      .then(function () {
        return callback(null, null)
      })
  }

  withdrawBet(account, callback) {
    return this.contract.methods.withdraw().send({from: account})
      .on('confirmation', function (confirmationNumber, receipt) {
        if (confirmationNumber >= 5) {
          return callback(null, receipt)
        }
      })
      .on('error', console.error)
      .then(function () {
        return callback(null, null)
      })
  }


  getBetRevealed(roundId, callback) {
    return this.contract.methods.betRevealed(roundId).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }

  getRoundInfo(roundId, callback) {
    return this.contract.methods.rounds(roundId).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }


  reviewerBet(account, betId, guess, nonce, secret, callback) {
    return this.contract.methods.revealBet(betId, nonce, guess, this.web3.utils.utf8ToHex(secret)).send({from: account})
      .on('confirmation', function (confirmationNumber, receipt) {
        if (confirmationNumber == 5) {
          return callback(null, receipt)
        }
      })
      .on('error', console.error)
      .then(function () {
        return callback(null, null)
      })
  }

  getWithdraw(account, callback) {
    return this.contract.methods.balancesForWithdraw(account).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }

  getBetIds(round, callback) {
    return this.contract.methods.getBetIds(round).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }

  getBetInfo(bet, callback) {
    return this.contract.methods.bets(bet).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }

  getRoundResult(account, round, callback) {
    return this.contract.methods.getJackpotResults(round).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, info)
    })
  }

  getCurrentBlock(callback) {
    return this.web3.eth.getBlockNumber(callback)
  }

  getWithdrawBalance(account, callback) {
    return this.contract.methods.balancesForWithdraw(account).call({}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(err, this.bal2num(info))
    })
  }


}
export {
  Pls
}
