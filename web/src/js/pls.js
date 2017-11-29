'use strict'
var abi = require('ethereumjs-abi')
var Web3 = require('web3')
if (typeof $ == 'undefined' && typeof require === 'function') {
  var $ = require('jquery');
}
class Pls {
  constructor(web3url, contractAddr, contractABI, tokenAddr, tokenABI) {
    if (!web3url) {
      web3url = 'http://localhost:8545'
    }
    if (web3url.currentProvider) {
      this.web3 = new Web3(web3.currentProvider)
    }
    else if (typeof web3url === 'string') {
      this.web3 = new Web3(new Web3.providers.HttpProvider(web3url))
    }
    this.contract = new this.web3.eth.Contract(contractABI, contractAddr);
    this.token = new this.web3.eth.Contract(tokenABI, tokenAddr);
    this.decimals = 0
    this.secret = this.web3.utils.utf8ToHex('ethereum');
    this.tokenAddress = tokenAddr
    this.contractAddress = contractAddr
    console.log('this.secret', this.secret)
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

  calAbi(secretHash) {
    return abi.methodID('startRoundWithFirstBet', ['uint256', 'uint256', 'uint256', 'bytes32']).toString('hex') +
      abi.rawEncode(['uint256', 'uint256', 'uint256', 'bytes32'], ["2", "100", "100", secretHash]).toString('hex')
  }


  SecretHash(account, guess, callback) {
    let nonce = 256
    return this.contract.methods.calculateSecretHash(nonce, guess, this.secret).call({from: account}, (err, info) => {
      if (err) {
        console.error(err)
        return callback(err)
      }
      return callback(null, this.calAbi(info))
    })
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
    console.log('this.web3.version', this.web3.version)
    return this.web3.eth.getAccounts(callback);
  }

  getTokenInfo(account, callback) {
    const nameDefer = $.Deferred();
    const symbolDefer = $.Deferred();
    const decimalsDefer = $.Deferred();
    const balanceDefer = $.Deferred();
    this.token.methods.name().call((err, name) =>
      err ? nameDefer.reject(err) : nameDefer.resolve(name));
    this.token.methods.symbol().call((err, symbol) =>
      err ? symbolDefer.reject(err) : symbolDefer.resolve(symbol));
    this.token.methods.decimals().call((err, decimals) =>
      err ? decimalsDefer.reject(err) : decimalsDefer.resolve(decimals));
    this.token.methods.balanceOf(account).call((err, balance) =>
      err ? balanceDefer.reject(err) : balanceDefer.resolve(balance));

    return $.when(nameDefer, symbolDefer, decimalsDefer, balanceDefer)
      .then((name, symbol, decimals, balance) => {
          this.decimals = decimals;
          console.log(decimals, balance)
          symbol = this.web3.utils.hexToAscii(symbol)
          name = this.web3.utils.hexToAscii(name)
          callback(null, {name, symbol, decimals, balance: this.bal2num(balance)});
        },
        (err) => callback(err));
  }

  doBet(account, deposit, hexStrToBytes, callback) {
    // hexStrToBytes = this.web3.utils.hexToBytes(hexStrToBytes)
    return this.token.methods.balanceOf(account).call({from: account}, (err, balance) => {
      if (err) {
        return callback(err)
      } else if (!(balance >= deposit)) {
        return callback(new Error(`Not enough tokens.Token balance = ${this.bal2num(balance)}, required = ${this.bal2num(deposit)}`));
      }
      console.log('Token balance', this.tokenAddress, this.bal2num(balance));
      return this.token.methods.transfer(this.contractAddress, deposit, hexStrToBytes).send({from: account})
        .on('transactionHash', function (hash) {
          console.log('transactionHash', hash)
        })
        .on('receipt', function (receipt) {
          return callback(null, receipt)
        })
        .on('confirmation', function (confirmationNumber, receipt) {
          console.log('confirmation', confirmationNumber, receipt)
        })
        .on('error', console.error);
    });
  }

  buyToken(account, callback) {//购买token
    let amount = this.web3.utils.toWei('1', 'ether')
    console.log('amount.....', amount)
    return this.token.methods.mint(account, this.web3.utils.toWei('1000', "ether")).send({from: account})
      .on('transactionHash', function (hash) {
        console.log('transactionHash', hash)
      })
      .on('receipt', function (receipt) {
        return callback(null, receipt)
      })
      .on('confirmation', function (confirmationNumber, receipt) {
        console.log('confirmation', confirmationNumber, receipt)
      })
      .on('error', console.error);
  }
}
export {
  Pls
}
