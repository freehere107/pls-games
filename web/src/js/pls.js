'use strict'
var abi = require('ethereumjs-abi')
class Pls {
  constructor(web3url,
              contractAddr,
              contractABI,
              tokenAddr,
              tokenABI) {
    if (!web3url) {
      web3url = 'http://localhost:8545'
    }
    if (web3url.currentProvider) {
      this.web3 = new Web3(web3.currentProvider)
    }
    else if (typeof web3url === 'string') {
      this.web3 = new Web3(new Web3.providers.HttpProvider(web3url))
    }
    this.contract = this.web3.eth.contract(contractABI).at(contractAddr)
    this.token = this.web3.eth.contract(tokenABI).at(tokenAddr)
    this.decimals = 0
  }

  encodeHex(str, zPadLength) {
    if (typeof str === "number") {
      str = str.toString(16);
    } else {
      str = [...str].map((char) =>
        char.charCodeAt(0).toString(16).padStart(2, '0'))
        .join('');
    }
    return str.padStart(zPadLength, '0');
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
    return this.web3.eth.getAccounts(callback);
  }

  joinBet(account) {
    return this.contract.startRoundWithFirstBet.call(2, 100, 100, this.encodeHex('first', 8),
      {from: account}, (err, info) => {
        console.log(err)
        console.log(info)
      }
    )
  }

  calAbi() {
    return abi.methodID('startRoundWithFirstBet', ['uint256', 'uint256', 'uint256', 'bytes32']).toString('hex') + abi.rawEncode(['uint256', 'uint256', 'uint256', 'bytes32'], ["2", "100", "100", "0xd4c1926f4e6406b47216b65d7b4737d133996f3bfb929bf785d4c29731068268"]).toString('hex')
  }

  SecretHash(guess) {
    return this.contract.startRoundWithFirstBet.call(),
      {from: account}, (err, info) => {

    }
  }

}
export {
  Pls
}
