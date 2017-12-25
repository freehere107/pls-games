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
            <p v-if="balance_value < 1000">Tip: The game needs 1000 PLS for each game, you can go
              <a href="https://etherdelta.com/#0xe43ac1714f7394173b15e7cff31a63d523ce4fb9-ETH"
                 target="_blank">Etherdelta</a> to buy PLS</p>
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
            <p v-if="roundsInfo[currentRound]">start Bet Block {{ roundsInfo[currentRound]['startBetBlock'] }}</p>
            <p
              v-if="roundsInfo[currentRound] && roundsInfo[currentRound]['startRevealBlock']>0">start Reveal Block {{ roundsInfo[currentRound]['startRevealBlock'] }}</p>
            <p>current Block {{ current_block }}</p>
            <p>withdraw balance {{ withdraw_balance }}</p>
            <Button type="success" size="small" class="new-bet" @click="new_bet_modal = true">Bet With New Round</Button>
            <Button type="info" size="small" class="new-bet" @click="reveale" v-if="!revealed && currentBet">Reveal Bet</Button>
            <Button type="info" size="small" class="new-bet" @click="betWithRound(true)"
                    v-if="!revealed && currentBet===null && currentRound>1">Bet this Round
            </Button>
            <Button type="primary" size="small" v-if="revealed && currentBet" @click="settle()">Finalize THE BET</Button>
          </Card>
          </Col>
          <Col span="24">
          <Card>
            <p slot="title">Rounds Choose</p>
            <i-circle v-for="(value,key) in roundCount <= 1 ? 0 : roundCount - 1" :percent="currentRound==value?100:0">
              <h4 v-on:click="changeRound(value)"> Round {{ value }}</h4>
              <div v-if="roundsInfo[value]">
                <a v-for="(item,index) in roundsInfo[value]['bet_ids']" v-on:click="showBet(item)">
                  <i class="ivu-icon ivu-icon-person"></i>
                  P{{ index+1 }}
                </a>
              </div>
              <br>
              <span class="demo-Circle-inner" style="font-size:12px"> {{ roundsInfo[value]|status(roundsInfo[value],current_block) }} </span>
            </i-circle>
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
        <Modal v-model="desc_modal" title="Rules of Bet Game (Please use chrome and  metamask Plug-ins)" width="900" cancel-text="">
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
          <p>Tip: The game needs 1000 PLS for each game, you can go
            <a href="https://etherdelta.com/#0x221789a8263eb084a7f575b195190cc3373b0c7a-ETH"
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
        contractAddr: '0x32ceb540334300bcd53836a25a4bd64d607babd8',
        tokenAddr: '0xe43ac1714f7394173b15e7cff31a63d523ce4fb9',
        tokenOwner: '0x15799d3098715234657b90261fc596914e5003aa',
        modal_loading: false,
        new_bet_modal: false,
        bet_modal: false,
        desc_modal: true,
        current_block: 0,
        one_bet_modal: true,
        spinShow: false,
        revealed: false,
        account: '',
        balance: 0,
        balance_value: 0,
        roundCount: 0,
        betCount: 0,
        withdraw: false,
        currentRound: 1,
        currentBet: null,
        finalizedBlock: 0,
        withdraw_balance: 0,
        currentPage: 0,
        roundsInfo: {},
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
      status: function (data, current_block) {
        if (data) {
          if (data.finalizedBlock > 0) {
            return 'Over'
          } else if (data.startRevealBlock > 0 && data.startRevealBlock + 100 <= current_block) {
            return 'Reveal'
          } else if (data.startRevealBlock > 0 && data.startRevealBlock + 100 > current_block) {
            return 'Over'
          } else if (data.startBetBlock + 100 < current_block) {
            return 'Over'
          } else {
            return 'Going'
          }
        } else {
          return 'Going'
        }

      }
    },
    methods: {
      init: function () {
        this.spinShow = true
        this.axios.get('static/betGame.json').then(r => {
          window.pls = new Pls('http://localhost:8545', this.contractAddr, r.data.betGame, this.tokenAddr, r.data.pls)
          this.getBlock()
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
            let getRevealed = this.getRevealed(accounts[0])
            let that = this
            Promise.all([getRounds, getToken, getBet, getRevealed]).then(result => {
              that.spinShow = false
              that.getRoundList()
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
            that.balance_value = `${token.balance || 0}`
            resolve(1)
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
              resolve(1)
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
          if (that.roundCount <= 1) {
            resolve(true)
          } else {
            pls.getBetRevealed(that.currentRound, (err, result) => {
              if (err) {
                console.error(err)
              } else {
                that.revealed = result
                console.log('getRevealed', result, that.currentRound)
                pls.getRoundInfo(that.currentRound, (err, result) => {
                  that.finalizedBlock = result.finalizedBlock
//                  if (result.finalizedBlock > 0) {
//                    pls.getWithdraw(that.account, (err, result) => {
//                      console.log('getWithdraw', result)
//                      that.withdraw = result
//                    });
//                  }
                  resolve(true)
                })
              }
            })
          }
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
        let secret = Math.floor(Math.random() * 10000000)
        let nonce = 1
        if (localStorage.getItem('nonce')) {
          nonce = isNaN(Math.floor(localStorage.getItem('nonce'))) ? 1 : Math.floor(localStorage.getItem('nonce')) + 1
        }
        localStorage.setItem('nonce', nonce)
        pls.SecretHash(this.account, guessResult, 'startRoundWithFirstBet', this.currentRound, secret, nonce, (err, result) => {
          if (err) {
            console.error(err)
          }
          console.log('startRound', result)
          pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
            if (err) {
              this.spinShow = false
              console.error(err)
            }
            localStorage.setItem(this.account + '-' + `${this.roundCount}`,
              JSON.stringify({
                'guess': guessResult, 'betId': this.betCount, 'secret': secret, 'nonce': nonce
              }))
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
        let secret = Math.floor(Math.random() * 10000000)
        let nonce = 1
        if (localStorage.getItem('nonce')) {
          nonce = isNaN(Math.floor(localStorage.getItem('nonce'))) ? 1 : Math.floor(localStorage.getItem('nonce')) + 1
        }
        localStorage.setItem('nonce', nonce)
        console.log(this.account, guessResult, 'betWithRound', this.currentRound)
        pls.getBetInfo(this.roundsInfo[this.currentRound]['bet_ids'][0], (err, bet) => {
          guessResult = bet.guessOdd === false
          pls.SecretHash(this.account, guessResult, 'betWithRound', this.currentRound, secret, nonce, (err, result) => {
            if (err) {
              console.error(err)
            }
            pls.doBet(this.account, 1000, '0x' + result, (err, result) => {
              if (err) {
                this.spinShow = false
                console.error(err)
              } else {
                localStorage.setItem(this.account + '-' + `${this.currentRound}`,
                  JSON.stringify({
                    'guess': guessResult, 'betId': this.betCount, 'secret': secret, 'nonce': nonce
                  }))
                this.refreshAccounts()
                console.log('bet success')
              }
            })
          })
        })
      },
      reveale: function () {
        this.spinShow = true
        if (this.currentBet === null) {
          console.error('review error')
          return
        }
        console.log('this.currentBet', this.currentBet)
        pls.reviewerBet(this.account, this.currentBet.betId, this.currentBet.guess, this.currentBet.nonce,
          this.currentBet.secret, (err, result) => {
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
      getRoundList: function () {
        let round_count = this.roundCount <= 1 ? 0 : this.roundCount - 1
        console.log('round_count', round_count)
        if (round_count > 0) {
          let that = this
          let promise_arr = []
          for (let i = 1; i <= round_count; i++) {
            promise_arr.push(that.getOneRound(i))
          }
          Promise.all(promise_arr).then(function (result) {
            console.log('getRoundList', that.roundsInfo)
          }, function (error) {
            console.error(error)
          })
        }
      },
      getOneRound: function (roundIndex) {
        let that = this
        return new Promise(function (resolve, reject) {
          pls.getRoundInfo(roundIndex, (err, round) => {
            if (err) {
              console.error(err)
            } else {
              pls.getRoundResult(that.account, roundIndex, (err, result) => {
                pls.getBetIds(roundIndex, (err, bet_ids) => {
                  if (err) {
                    console.error(err)
                  } else {
                    console.log('bet_ids', bet_ids)
                    round['bet_ids'] = bet_ids
                    round['round_index'] = roundIndex
                    round['round_result'] = result['2']
                    that.roundsInfo[roundIndex] = round
                    resolve(true)
                  }
                })
              })
            }
          })
        })
      },
      showBet: function (betIndex) {
        pls.getBetInfo(betIndex, (err, bet) => {
          if (err) {
            console.error(err)
          } else {
            this.$Modal.info({
              title: 'bet info',
              content: '<p>player:' + bet.player + '</p><br><p>guess:' + 'even' + '</p>'
            });
            console.log('bet info ', bet)
          }
        })
      },
      getBlock(){
        pls.getCurrentBlock((err, count) => {
          if (err) {
            console.error(err)
          } else {
            this.current_block = count
          }
        })
      },
      getWithdraw(){
        pls.getWithdrawBalance((err, count) => {
          if (err) {
            console.error(err)
          } else {
            this.withdraw_balance = count
          }
        })
      }
    },
    created()
    {
      this.init()
      setTimeout("console.log('start')", 3000)
    }
  }
</script>
