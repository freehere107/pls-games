<style scoped>
  .layout {
    border: 1px solid #d7dde4;
    background: #f5f7f9;
  }

  .layout-assistant {
    width: 100%;
    margin: 0 auto;
    height: inherit;
  }

  .layout-content {
    min-height: 50px;
    margin: 15px;
    overflow: hidden;
    background: #fff;
    border-radius: 4px;
  }

  .layout-content-main {
    padding: 10px;
  }

  .account {
    margin-left: 2%;
    margin-right: 2%;
  }
</style>
<template>
  <div class="layout">
    <Menu mode="horizontal" active-name="1">
      <div class="layout-assistant">
        <MenuItem name="1">Round 1</MenuItem>
        <MenuItem name="2">Round 2</MenuItem>
        <MenuItem name="3">Round 3</MenuItem>
        <MenuItem name="4">Round 4</MenuItem>
        <MenuItem name="5">Round 5</MenuItem>
      </div>
    </Menu>
    <div class="layout-content">
      <div class="layout-content-main">
        <div class="demo-avatar-badge">
          <Badge count="1">
            <Avatar shape="square" icon="person" style="background-color: #87d068"/>
          </Badge>
          <span class="account">Account : {{ account }}</span>
          <span class="account">balance : {{ balance }}</span>
          <span class="account">round : {{ roundCount }}</span>
          <span class="account">BetCount : {{ BetCount }}</span>

          <Slider v-model="value1"></Slider>
          <Button type="primary" shape="circle" @click="payToken">By Token</Button>
          <Button type="success" shape="circle" @click="startRound('odd')">To bet odd</Button>
          <Button type="success" shape="circle" @click="startRound('even')">To bet even</Button>
        </div>
      </div>
    </div>
    <div class="layout-content">
      <div class="layout-content-main">
        <Badge count="2">
          <Avatar shape="square" icon="person"/>
        </Badge>
        <span class="account">Account : player2</span>
        <Slider v-model="value2"></Slider>
        <Button type="success" shape="circle" @click="betWithRound('odd')">To bet odd</Button>
        <Button type="success" shape="circle" @click="betWithRound('even')">To bet even</Button>
      </div>
    </div>
    <div class="layout-content">
      <div class="layout-content-main">
        <Badge count="3">
          <Avatar shape="square" icon="person"/>
        </Badge>
        <span class="account">Account : player3</span>
        <Slider v-model="value3"></Slider>
      </div>
    </div>
    <Button type="warning" shape="circle" @click="settle()">Settle this Bet</Button>
  </div>
</template>
<script>
  import {Pls} from '../js/pls'
  export default {
    data () {
      return {
        contractAddr: '0xbe8e10e0c8ce6fba62bdaf9cee9e6a6bd5656d37',
        tokenAddr: '0x221789a8263eb084a7f575b195190cc3373b0c7a',
        account: '',
        value1: 0,
        value2: 0,
        value3: 0,
        value4: 0,
        balance: 0,
        roundCount: 0,
        BetCount: 0,
      }
    },
    methods: {
      init: function () {
        this.axios.get('static/betGame.json').then(r => {
          window.pls = new Pls(
            'http://localhost:8545',
            this.contractAddr,
            r.data.betGame,
            this.tokenAddr,
            r.data.pls
          )
          this.refreshAccounts()
        }).catch(err => {
          console.log(`error is ${err}`)
        })
      },
      refreshAccounts: function () {
        pls.getAccounts((err, accounts) => {
          if (err || !accounts || !accounts.length) {
            setTimeout(this.refreshAccounts, 1000)
          } else {
            this.account = accounts[0]
            pls.getTokenInfo(this.account, (err, token) => {
              if (err) {
                console.log(err)
              }
              console.log('get token info', token)
              this.balance = `${token.balance || 0} ${token.symbol}`
              pls.getRoundCount(this.account, (err, result) => {
                this.roundCount = result;
                console.log('getRoundCount', err, result)
              })
              pls.getBetCount(this.account, (err, result) => {
                this.BetCount = result;
                console.log('getBetCount', err, result)
              })
            })
            console.log('current account ', accounts)
          }
        });
      },
      payToken: function () {
        console.log('payToken')
        pls.buyToken(this.account, (err, result) => {
          if (err) {
            console.error(err);
          } else {
            console.log('payToken over', result)
            this.refreshAccounts()
          }
        })
      },
      startRound: function (guess) {
        let result = guess == 'odd'
        pls.SecretHash(this.account, result, 'startRoundWithFirstBet', (err, result) => {
          if (err) {
            console.error(err)
          }
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              console.error(err)
            }
            this.refreshAccounts()
            console.log('bet success')
          })
        })
      },
      betWithRound: function (guess) {
        let result = guess == 'odd'
        pls.SecretHash(this.account, result, 'betWithRound', (err, result) => {
          if (err) {
            console.error(err)
          }
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              console.error(err)
            }
            this.refreshAccounts()
            console.log('bet success')
          })
        })
      },
      settle: function () {
        pls.settleBet(this.roundCount, this.account, (err, result) => {
          if (err) {
            console.error(err)
          }
        })
      }

    },
    created(){
      this.init()
    }
  }
</script>
