<style scoped>
  .layout {
    overflow: hidden;
    height: 100%;
  }

  .layout-content {
    min-height: 400px;
    margin: 0 6% 4% 6%;
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

  a:link {
    color: #000000;
    text-decoration: none;
  }
  a:visited {
    color: #000000;
    text-decoration: none;
  }
  a:hover {
    color: #999999;
    text-decoration: underline;
  }
</style>
<template>
  <div class="layout">
    <div class="layout-content">
      <div class="layout-content-main">
        <Row>
          <Col span="12">
          <Card>
            <a slot="title" href="javascript:void(0)">User</a>
            <p>Account : {{ account }}</p>
            <p>Balance : {{ balance }}</p>
          </Card>
          </Col>
          <Col span="12">
          <Card>
            <a slot="title" v-on:click="desc_modal = true" href="javascript:void(0)" class="bet-round">Bet Round
              <i class="ivu-icon ivu-icon-ios-information-outline"></i>
            </a>
            <p>Current Round : {{ currentRound }}</p>
            <p>All Rounds : {{ roundCount<=1?0:roundCount-1 }}</p>
          </Card>
          </Col>
          <Col span="24">
          <Card>
            <p slot="title">Current Round Information</p>
            <Button type="success" size="small" class="new-bet" @click="new_bet_modal = true">New Bet</Button>
            <Button type="info" size="small" class="new-bet" @click="reveale" v-if="!revealed && currentBet">Reveal Bet</Button>
            <Button type="info" size="small" class="new-bet" @click="bet_modal = true" v-if="!revealed && currentBet===null">Bet this Round</Button>
            <Button type="primary" size="small" v-if="revealed && currentBet" @click="settle()">Finalize THE BET</Button>
          </Card>
          </Col>
          <Col span="24">
          <Card>
            <p slot="title">Rounds Choose</p>
            <Button type="success" size="small" class="new-bet" @click="changeRound(n)" v-for="n in roundCount<=1?0:roundCount-1>10?10:roundCount-1">
              Round {{ n + currentPage*10 }}
            </Button>
            <br>
            <br>
          </Card>
          </Col>

        </Row>
        <br/>
        <Row>
          <Col span="3" push="10">
          <Page :current="currentRound" :total="roundCount<=1?0:roundCount-1" :page-size="10" @on-change="changePage" simple></Page>
          </Col>
        </Row>
        <Row>
          <Col span="24">
          <div class="token-sell">
            <h3 v-if="account===tokenOwner">Token Mint</h3>
            <h3 v-if="account!=tokenOwner">Token Transfer</h3>
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
              <FormItem style="margin-bottom: 0;">
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
        <Modal v-model="desc_modal" title="Rules of Bet Game" width="900">
          <p>Bet Game is separated to a list of rounds, for every round, every player will join in by putting an bet here, the contract will automatically calculate a game result according to the secret of these bets, which is an odd or an even, according the sum of the secrets of the bets. Every player will get reward according to their guess settings in the origin bet, they will win and get reward if they guess the right answer, otherwise they will lose.</p>
          <br/>
          <p>Every one can trigger the round finalization action once all bets are full filled and all bets are revealed. But if someone forget to reveal the bet in specific time(there will one round parameter controlling this: _maxRevealBlockCount), the round will fail to reveal, the funds of the players who revealed will be returned back, but the funds of players who didn't reveal in time will be punished and be confiscated to the finalizer and contract owner.</p>
          <br/>
          <p>There are some import parameters need to set:</p>
          <br/>
          <ul>
            <li>1. The total "betCount" that will happen in the round, which means the how many bets should be played for this round. The player who start a new round(room),and join with his bet can use "startRoundWithFirstBet". The suggested betCount for easy to find counter-party player, is just 2.</li>
            <br/>
            <li>2. The parameters of one round includes:
              <ul>
                <li>&nbsp&nbsp a. _betCount, the count of the bets.</li>
                <li>&nbsp&nbsp b. _maxBetBlockCount, the max waiting bet count till finalizing the round, that is, anyone can finalize the round after "_maxBetBlockCount" from the first bet.</li>
                <li>&nbsp&nbsp c. _maxRevealBlockCount, not implemented, supposed to be the max waiting reveal block count till finalizing the round, that is, anyone can finalize the round after "_maxRevealBlockCount" from the last bet block.</li>
                <li>&nbsp&nbsp d. _secretHashForFirstBet, this is the hash of the guess and secret settled by the player, which is also the result of "calculateSecretHash(uint _nonce, bool _guessOdd, bytes32 _secret)", the "nonce" here is just a random number. The "_guessOdd"</li>
              </ul>
            </li>
            <br/>
            <li>3. After some round are created, other players can join that room, and full fill one of the left bets positions with their guess and secret settings.</li>
            <br/>
            <li>4. After all the bet positions are full filled by the players, then the process of secret revealing begins. Every player of bets in this round are required to reveal their bets. The bet secrets(nonce, guess, secret) are actually stored in user's end browser. so they just click the reveal to send transactions.</li>
            <br/>
            <li>5. After all the bet are revealed (in revealed status), then any player or any one can trigger to finalize the round to see the result to check whether they win or not. But if the bet are not revealed and the block of (_maxRevealBlockCount) arrived, any one can trigger to cancel this round, players who revealed their bets will get refunded, but those who didn't will lose their funds.</li>
            <br/>
            <li>6. The round ends.</li>
            <br/>
          </ul>
          <p>Tip: The game needs 1000 PLS for each game, you can go <a href="https://etherdelta.com/#0x221789a8263eb084a7f575b195190cc3373b0c7a-ETH"
                                                                       target="_blank">Etherdelta</a> to buy PLS in Kovan test network</p>
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
        contractAddr: '0xF399B93859A8a003708aA9cBAAE12D8e8B76591d',
        tokenAddr: '0x221789a8263eb084a7f575b195190cc3373b0c7a',
        tokenOwner: '0x00a1537d251a6a4c4effAb76948899061FeA47b9',
        modal_loading: false,
        new_bet_modal: false,
        bet_modal: false,
        desc_modal: true,
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
        currentPage: 0,
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
      changePage: function (page) {
        this.currentPage = page
        console.log('changePage', page)
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
              that.roundCount = parseInt(result)
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
                console.log('getRoundInfo', result)
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
            if (this.account === this.tokenOwner) {
              pls.mintToken(this.account, this.formInline.address, this.formInline.token, (err, result) => {
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
              pls.transToken(this.account, this.formInline.address, this.formInline.token, (err, result) => {
                if (err) {
                  this.spinShow = false
                  console.error(err)
                } else {
                  console.log('transToken over', result)
                  this.$Message.success('Success!')
                  this.refreshAccounts()
                }
              })
            }
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
          pls.withdrawBet(this.account, (err, result) => {
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
