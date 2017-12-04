<style scoped>
  .layout {
    border: 1px solid #d7dde4;
    background: #f5f7f9
  }

  .token-sell {
    padding: 3%
  }

  .action-button {
    margin-right: 2rem;
    margin-left: 2rem
  }
</style>
<template>
  <div class="layout">
    <Menu mode="horizontal" :theme="theme1" active-name="1" @on-select="menuAction">
      <MenuItem name="bet">
        <Icon type="ios-paper"></Icon>
        Bet
      </MenuItem>
      <MenuItem name="review" v-if="!Revealed && currentBat">
        <Icon type="ios-people"></Icon>
        Review
      </MenuItem>
      <Submenu name="3">
        <template slot="title">
          <Icon type="stats-bars"></Icon>
          New
        </template>
        <MenuGroup title="Bet">
          <MenuItem name="odd">Odd</MenuItem>
          <MenuItem name="even">Even</MenuItem>
        </MenuGroup>
      </Submenu>
      <MenuItem name="4" v-if="account===tokenOwner">
        <Icon type="ios-paper"></Icon>
        Token
      </MenuItem>

    </Menu>
    <Row>
      <Col span="12">
      <Card>
        <p slot="title">Current User</p>
        <p>Account : {{ account.substring(0,12) }}</p>
        <p>balance : {{ balance }}</p>
        <p>Revealed : {{ Revealed }}</p>
      </Card>
      </Col>
      <Col span="12">
      <Card>
        <p slot="title">Bet Round</p>
        <p>Current : {{ currentRound }}</p>
        <p>Rounds : {{ roundCount }}</p>
        <p>Bets : {{ BetCount }}</p>
      </Card>
      </Col>
    </Row>
    <Row v-if="account===tokenOwner">
      <Col span="24">
      <div class="layout-content token-sell">
        <h3>Token sell</h3>
        <Form ref="formInline" :model="formInline" :rules="ruleInline">
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
      </Col>
    </Row>
    <Row type="flex" class-name="action-button">
      <Col span="24">
      <Input v-model="currentRound" icon="ios-clock-outline" style="width: 200px" min="1"></Input>
      <Button type="primary" v-if="currentBat===null && roundCount>1" size="large" @click="betWithRound('odd')">
        Odd
      </Button>
      <Button type="primary" v-if="currentBat===null && roundCount>1" size="large" @click="betWithRound('even')">
        Even
      </Button>
      <Button type="success" size="large" v-if="Revealed && currentBat" @click="settle()">
        SETTLE THE BET
      </Button>
      </Col>
    </Row>
    <Spin size="large" fix v-if="spinShow"></Spin>
  </div>
</template>
<script>
  import {Pls} from '../js/pls'
  export default {
    data () {
      return {
        theme1: 'dark',
        contractAddr: '0x3fb7112fc3b266ff4532bbfe4130179c0397f690',
        tokenAddr: '0x221789a8263eb084a7f575b195190cc3373b0c7a',
        tokenOwner: '0x00a1537d251a6a4c4effAb76948899061FeA47b9',
        account: '',
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
      },
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
                this.roundCount = result
                let currentBat = localStorage.getItem(this.account + '-' + `${this.currentRound}`)
                this.currentBat = currentBat === null ? null : JSON.parse(currentBat)
                pls.getBetCount(this.account, (err, result) => {
                  this.BetCount = result
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
        })
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
                this.$Message.success('Success!')
                this.refreshAccounts()
              }
            })
          } else {
            this.spinShow = false
            this.$Message.error('Fail!')
          }
        })
      },
      menuAction: function (name) {
        switch (name) {
          case 'review':
            this.reviewBat()
            break
          case 'odd':
            this.startRound('odd')
            break
          case 'even':
            this.startRound('even')
            break
        }
      },
      //open new pls
      startRound: function (guess) {
        console.log('guess', guess)
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
