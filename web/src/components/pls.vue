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
    <h1>Round : {{ roundCount }}</h1>
    <h1>BetCount : {{ BetCount }}</h1>
    <div>
      <span style="font-size: 1.5rem">new bat</span>
      <Button type="success" shape="circle" @click="startRound('odd')">To bet odd</Button>
      <Button type="success" shape="circle" @click="startRound('even')">To bet even</Button>
    </div>
    <label>Jump to Round</label>
    <input type="number" name="jump" v-model="currentRound" v-bind:max="roundCount" min="1">
    <Menu mode="horizontal">
      <div class="layout-assistant">
        <MenuItem :name="currentRound">Round {{currentRound}}</MenuItem>
      </div>
    </Menu>
    <div class="layout-content token-sell" v-if="account===tokenOwner">
      <h3>Token sell</h3>
      <Form ref="formInline" :model="formInline" :rules="ruleInline" inline>
        <FormItem prop="token">
          <Input type="text" v-model="formInline.token" placeholder="token" min="1">
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
          <p class="account">Account : {{ account }}</p>
          <p class="account">balance : {{ balance }}</p>
          <p class="account">Revealed : {{ Revealed }}</p>
          <div v-if="currentBat===null && roundCount>1">
            <h2>join bat</h2>
            <Button type="primary" shape="circle" @click="betWithRound('odd')">To bet odd</Button>
            <Button type="primary" shape="circle" @click="betWithRound('even')">To bet even</Button>
          </div>
        </div>
      </div>
    </div>
    <Button type="warning" shape="circle" @click="reviewBat()" v-if="!Revealed && currentBat">reviewBat</Button>
    <Button type="warning" shape="circle" @click="settle()" v-if="Revealed && currentBat">Settle this Bet</Button>
    <Spin size="large" fix v-if="spinShow"></Spin>
  </div>
</template>
<script>
  import {Pls} from '../js/pls'
  export default {
    data () {
      return {
        contractAddr: '0xf6e690b482ab44ad93190aafc048fea5d3d074dc',
        tokenAddr: '0x221789a8263eb084a7f575b195190cc3373b0c7a',
        tokenOwner: '0x00a1537d251a6a4c4effAb76948899061FeA47b9',
        account: '',
        value1: 0,
        spinShow: false,
        balance: 0,
        roundCount: 0,
        BetCount: 0,
        currentRound: 1,
        currentBat: null,
        Revealed: false,
        formInline: {
          token: '',
          address: ''
        },
        ruleInline: {
          token: [
            {required: true, message: 'Please fill in the token', trigger: 'blur'}
          ],
          address: [
            {required: true, message: 'Please fill in the address.', trigger: 'blur'}
          ]
        }
      }
    },
    watch: {
      currentRound: function (newRound) {
        this.refreshAccounts()
        console.log('currentRound', newRound)
      }
    },
    methods: {
      init: function () {
        this.spinShow = true
        this.axios.get('static/betGame.json').then(r => {
          window.pls = new Pls('http://localhost:8545', this.contractAddr, r.data.betGame, this.tokenAddr, r.data.pls)
          this.refreshAccounts()
        }).catch(err => {
          console.log(`error is ${err}`)
        })
      },
      //get current account info
      refreshAccounts: function () {
        this.spinShow = true
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
                let currentBat = localStorage.getItem(this.account + '-' + `${this.currentRound}`)
                this.currentBat = currentBat === null ? null : JSON.parse(currentBat)
                pls.getBetCount(this.account, (err, result) => {
                  this.BetCount = result;
                  pls.getBatRevealed(this.currentRound, (err, result) => {
                    console.log('pls.getBatRevealed', this.currentRound, result)
                    this.Revealed = result
                  })
                  this.spinShow = false
                })
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
            this.spinShow = true
            pls.buyToken(this.account, this.formInline.address, this.formInline.token, (err, result) => {
              if (err) {
                this.spinShow = false
                console.error(err)
              } else {
                console.log('payToken over', result)
                this.$Message.success('Success!');
                this.refreshAccounts()
              }
            })
          } else {
            this.spinShow = false
            this.$Message.error('Fail!');
          }
        })
      },
      //open new pls
      startRound: function (guess) {
        this.spinShow = true
        let guessResult = guess == 'odd'
        pls.SecretHash(this.account, guessResult, 'startRoundWithFirstBet', this.currentRound, (err, result) => {
          if (err) {
            console.error(err)
          }
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              console.error(err)
            }
            localStorage.setItem(this.account + '-' + `${this.roundCount}`, JSON.stringify({'guess': guessResult, 'betId': this.BetCount}))
            this.refreshAccounts()
            console.log('bet success')
          })
        })
      },
      //bet with exist round
      betWithRound: function (guess) {
        let guessResult = guess == 'odd'
        this.spinShow = true
        console.log(this.account, guessResult, 'betWithRound', this.currentRound)
        pls.SecretHash(this.account, guessResult, 'betWithRound', this.currentRound, (err, result) => {
          if (err) {
            console.error(err)
          }
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              console.error(err)
            }
            localStorage.setItem(this.account + '-' + `${this.currentRound}`, JSON.stringify({'guess': guessResult, 'betId': this.BetCount}))
            this.refreshAccounts()
            console.log('bet success')
          })
        })
      },
      reviewBat: function () {
        this.spinShow = true
        if (this.currentBat === null) {
          console.error('review error')
          return
        }
        pls.reviewerBat(this.currentBat.betId, this.currentBat.guess, (err, result) => {
          if (err) {
            console.error(err)
          } else {
            console.log('reviewBat result ', result)
            this.refreshAccounts()
          }
        })
      },
      //settle one bet
      settle: function () {
        this.spinShow = true
        pls.settleBet(this.currentRound, this.account, (err, result) => {
          if (err) {
            console.error(err)
          }
          this.refreshAccounts()
        })
      }

    },
    created(){
      this.init()
    }
  }
</script>
