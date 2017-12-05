<style scoped>
  .layout {
    overflow: hidden;
    height: 100%;
  }

  .layout-content {
    min-height: 400px;
    margin: 4% 6% 4% 6%;
    overflow: hidden;
    background: #fff;
    border-radius: 4px;
  }

  .layout-content-main {
    padding: 10px;
  }

  .new-bet {
    margin-right: 5px;
  }
</style>
<template>
  <div class="layout">
    <div class="layout-content">
      <div class="layout-content-main">
        <Row>
          <Col span="12">
          <Card>
            <p slot="title">User</p>
            <p>Account : {{ account }}</p>
            <p>Balance : {{ balance }}</p>
          </Card>
          </Col>
          <Col span="12">
          <Card>
            <p slot="title">Bet Round</p>
            <p>Current Round : {{ currentRound }}</p>
            <p>All Rounds : {{ roundCount }}</p>
          </Card>
          </Col>
          <Col span="24">
          <Card>
            <p slot="title">The Round</p>
            <Button type="success" size="small" class="new-bet" @click="new_bet_modal = true">New Bet</Button>
            <p>Revealed : {{ revealed | revealedStatus }}</p>
            <Button type="info" size="small" class="new-bet" @click="reveale" v-if="!revealed && currentBet">Reveal Bet</Button>
            <Button type="info" size="small" class="new-bet" @click="bet_modal = true" v-if="!revealed && currentBet===null">Bet this Round</Button>
            <Button type="primary" size="small" v-if="revealed && currentBet" @click="settle()">Finalize THE BET</Button>
          </Card>
          </Col>
        </Row>
        <br/>
        <br/>
        <Row>
          <Col span="3" push="10">
          <Page :current="currentRound" :total="roundCount" :page-size="1" @on-change="changeRound" simple></Page>
          </Col>
        </Row>
        <Row v-if="account===tokenOwner">
          <Col span="24">
          <div class="token-sell">
            <h3>Token sell</h3>
            <Form ref="formInline" :model="formInline" :rules="ruleInline">
              <FormItem prop="address">
                <Input type="text" v-model="formInline.address" placeholder="address">
                <Icon type="ios-locked-outline" slot="prepend"></Icon>
                </Input>
              </FormItem>
              <FormItem prop="token">
                <Input type="text" v-model="formInline.token" placeholder="token" min="1">
                <Icon type="ios-person-outline" slot="prepend"></Icon>
                </Input>
              </FormItem>
              <FormItem>
                <Button type="primary" @click="handleSubmit('formInline')">submit</Button>
              </FormItem>
            </Form>
          </div>
          </Col>
        </Row>
        <Modal v-model="new_bet_modal" title="Common Modal dialog box title">
          <p slot="header" style="color:#55b6ff;text-align:center">
            <Icon type="information-circled"></Icon>
            <span>New Bet?</span>
          </p>
          <div style="text-align:center">
            <p>Need to open a new game on the gambling game?</p>
            <p>What's you choose?</p>
          </div>
          <div slot="footer">
            <Button type="warning" size="large" :loading="modal_loading" @click="startRound('odd')">ODD</Button>
            <Button type="error" size="large" :loading="modal_loading" @click="startRound('even')">EVEN</Button>
          </div>
        </Modal>
        <Modal v-model="bet_modal" title="Common Modal dialog box title">
          <p slot="header" style="color:#55b6ff;text-align:center">
            <Icon type="information-circled"></Icon>
            <span>Bet this Round?</span>
          </p>
          <div style="text-align:center">
            <p>What's you choose?</p>
          </div>
          <div slot="footer">
            <Button type="warning" size="large" :loading="modal_loading" @click="betWithRound('odd')">ODD</Button>
            <Button type="error" size="large" :loading="modal_loading" @click="betWithRound('even')">EVEN</Button>
          </div>
        </Modal>

      </div>
    </div>
    <Spin size="large" fix v-if="spinShow"></Spin>
  </div>
</template>
<script>
  import {Pls} from '../js/pls'
  export default {
    data () {
      return {
        theme1: 'dark',
        contractAddr: '0xa68b9077f266902104739b7e80b3789b428f5ca5',
        tokenAddr: '0x221789a8263eb084a7f575b195190cc3373b0c7a',
        tokenOwner: '0x00a1537d251a6a4c4effAb76948899061FeA47b9',
        modal_loading: false,
        new_bet_modal: false,
        bet_modal: false,
        spinShow: false,
        revealed: false,
        account: '',
        balance: 0,
        roundCount: 0,
        betCount: 0,
        withdraw: false,
        currentRound: 1,
        currentBet: null,
        finalizedBlock: 0,
        formInline: {
          token: '',
          address: ''
        },
        ruleInline: {
          token: [{required: true, message: 'Please fill in the token', trigger: 'blur'}],
          address: [{required: true, message: 'Please fill in the address.', trigger: 'blur'}]
        }
      }
    },
    watch: {
      currentRound: function (round) {
        this.refreshAccounts()
        console.log(round)
      },
    },
    filters: {
      revealedStatus: function (status) {
        return status === true ? 'over' : 'going'
      }
    },
    methods: {
      init: function () {
        this.spinShow = true
        this.axios.get('static/betGame.json').then(r => {
          window.pls = new Pls('http://localhost:8545', this.contractAddr, r.data.betGame, this.tokenAddr, r.data.pls)
          this.refreshAccounts()
        }).catch(err => {
          console.error(`error is ${err}`)
        })
      },
      changeRound: function (round) {
        this.currentRound = round
        this.refreshAccounts()
      },
      //get current account info
      refreshAccounts: function () {
        this.spinShow = true
        pls.getAccounts((err, accounts) => {
          if (err || !accounts || !accounts.length) {
            setTimeout(this.refreshAccounts, 1000)
          } else {
            this.account = accounts[0]
            let getToken = this.getToken(accounts[0])
            let getRounds = this.getRounds(accounts[0])
            let getBet = this.getBet(accounts[0])
            let getRevealed = this.getRevealed()
            let that = this
            Promise.race([getToken, getRounds, getBet, getRevealed]).then(function (result) {
              that.spinShow = false
            }, function (error) {
              console.error(error)
            })
          }
        })
      },
      getToken: function (account) {
        let that = this
        return new Promise(function (resolve, reject) {
          pls.getTokenInfo(account, (err, token) => {
            if (err) {
              console.error(err)
            }
            that.balance = `${token.balance || 0} ${token.symbol}`
            resolve(true)
          })
        })
      },
      getRounds: function (account) {
        let that = this
        return new Promise(function (resolve, reject) {
          pls.getRoundCount(account, (err, result) => {
            if (err) {
              console.error(err)
            } else {
              that.roundCount = parseInt(result) - 1
              let currentBet = localStorage.getItem(account + '-' + `${that.currentRound}`)
              that.currentBet = currentBet === null ? null : JSON.parse(currentBet)
              resolve(true)
            }
          })
        })
      },
      getBet: function (account) {
        let that = this
        return new Promise(function (resolve, reject) {
          pls.getBetCount(account, (err, result) => {
            if (err) {
              console.error(err)
            } else {
              that.betCount = result
              resolve(true)
            }
          })
        })
      },
      getRevealed: function () {
        let that = this
        return new Promise(function (resolve, reject) {
          pls.getBetRevealed(that.currentRound, (err, result) => {
            if (err) {
              console.error(err)
            } else {
              that.revealed = result
              console.log('getRevealed', result, that.currentRound)
              pls.getRoundInfo(that.currentRound, (err, result) => {
                that.finalizedBlock = result.finalizedBlock
                if (result.finalizedBlock > 0) {
                  pls.getWithdraw(that.account, (err, result) => {
                    console.log('getWithdraw', result)
                    that.withdraw = result
                  });
                }
                resolve(true)
              })
            }
          })
        })
      },

      //owner send token to address
      handleSubmit(name)
      {
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
      //open new pls
      startRound: function (guess) {
        console.log('guess', guess)
        this.new_bet_modal = false
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
            localStorage.setItem(this.account + '-' + `${this.roundCount}`, JSON.stringify({'guess': guessResult, 'betId': this.betCount}))
            this.refreshAccounts()
            console.log('bet success')
          })
        })
      },
      //bet with exist round
      betWithRound: function (guess) {
        let guessResult = guess == 'odd'
        this.spinShow = true
        this.bet_modal = false
        console.log(this.account, guessResult, 'betWithRound', this.currentRound)
        pls.SecretHash(this.account, guessResult, 'betWithRound', this.currentRound, (err, result) => {
          if (err) {
            console.error(err)
          }
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              console.error(err)
            } else {
              localStorage.setItem(this.account + '-' + `${this.currentRound}`, JSON.stringify({'guess': guessResult, 'betId': this.betCount}))
              this.refreshAccounts()
              console.log('bet success')
            }
          })
        })
      },
      reveale: function () {
        this.spinShow = true
        if (this.currentBet === null) {
          console.error('review error')
          return
        }
        pls.reviewerBet(this.account, this.currentBet.betId, this.currentBet.guess, (err, result) => {
          if (err) {
            this.spinShow = false
            console.error(err)
          } else {
            this.refreshAccounts()
          }
        })
      },
      //settle one bet
      settle: function () {
        this.spinShow = true
        if (this.finalizedBlock == 0) {
          pls.settleBet(this.currentRound, this.account, (err, result) => {
            if (err) {
              this.spinShow = false
              console.error(err)
            }
            this.refreshAccounts()
          })
        } else {
          pls.withdrawbet(this.account, (err, result) => {
            if (err) {
              this.spinShow = false
              console.error(err)
            }
            this.refreshAccounts()
          })
        }

      },
    },
    created()
    {
      this.init()
    }
  }
</script>
