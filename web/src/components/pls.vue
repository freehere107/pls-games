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
    <h1>new bat</h1>
    <Button type="success" shape="circle" @click="startRound('odd')">To bet odd</Button>
    <Button type="success" shape="circle" @click="startRound('even')">To bet even</Button>
    <Menu mode="horizontal" active-name="1">
      <div class="layout-assistant">
        <MenuItem v-for="n in 10" name="n">Round {{n}}</MenuItem>
      </div>
    </Menu>
    <div class="layout-content token-sell" v-if="account===tokenOwner">
      <h3>Token sell</h3>
      <Form ref="formInline" :model="formInline" :rules="ruleInline" inline>
        <FormItem prop="token">
          <Input type="text" v-model="formInline.token" placeholder="token">
          <Icon type="ios-person-outline" slot="prepend"></Icon>
          </Input>
        </FormItem>
        <FormItem prop="address">
          <Input type="text" v-model="formInline.address" placeholder="address">
          <Icon type="ios-locked-outline" slot="prepend"></Icon>
          </Input>
        </FormItem>
        <FormItem>
          <Button type="primary" @click="handleSubmit('formInline')">submit</Button>
        </FormItem>
      </Form>
    </div>
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
          <div>
            <h2>join bat</h2>
            <Button type="primary" shape="circle" @click="betWithRound('odd')">To bet odd</Button>
            <Button type="primary" shape="circle" @click="betWithRound('even')">To bet even</Button>
          </div>
        </div>
      </div>
    </div>
    <Button type="warning" shape="circle" @click="reviewBat()">reviewBat</Button>
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
        tokenOwner: '0x00a1537d251a6a4c4effAb76948899061FeA47b9',
        account: '',
        value1: 0,
        balance: 0,
        roundCount: 0,
        BetCount: 0,
        //form
        formInline: {
          token: '',
          address: ''
        },
        ruleInline: {
          token: [
            {required: true, message: 'Please fill in the user name', trigger: 'blur'}
          ],
          address: [
            {required: true, message: 'Please fill in the address.', trigger: 'blur'}
          ]
        }
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
      //get current account info
      refreshAccounts: function () {
        pls.getAccounts((err, accounts) => {
          if (err || !accounts || !accounts.length) {
            setTimeout(this.refreshAccounts, 1000)
          } else {
            console.log('all accounts', accounts)
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
              pls.getBetRevealed(1, (err, result) => {
                console.log('getBetRevealed', err, result)
              })
            })
            console.log('current account ', accounts)
          }
        });
      },
      //owner send token to address
      handleSubmit(name) {
        this.$refs[name].validate((valid) => {
          if (valid) {
            pls.buyToken(this.account, this.formInline.address, this.formInline.token, (err, result) => {
              if (err) {
                console.error(err);
              } else {
                console.log('payToken over', result)
                this.$Message.success('Success!');
                this.refreshAccounts()
              }
            })
          } else {
            this.$Message.error('Fail!');
          }
        })
      },
      //open new pls
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
      //bet with exist round
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
      reviewBat: function (betId, guess) {
        pls.reviewerBet(betId, guess, (err, result) => {
          if (err) {
            console.error(err)
          }
        })
      },
      //settle one bet
      settle: function () {
        pls.settleBet(1, this.account, (err, result) => {
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
