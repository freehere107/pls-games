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
            <Avatar shape="square" icon="person"/>
          </Badge>
          player1
          <Slider v-model="value1"></Slider>
          <Button type="primary" shape="circle" @click="bet">To bet</Button>
        </div>
      </div>
    </div>
    <div class="layout-content">
      <div class="layout-content-main">
        <Badge count="2">
          <Avatar shape="square" icon="person"/>
        </Badge>
        player2
        <Slider v-model="value2"></Slider>
      </div>
    </div>
    <div class="layout-content">
      <div class="layout-content-main">
        <Badge count="3">
          <Avatar shape="square" icon="person"/>
        </Badge>
        player3
        <Slider v-model="value3"></Slider>
      </div>
    </div>
    <div class="layout-content">
      <div class="layout-content-main">
        <Badge count="4">
          <Avatar shape="square" icon="person"/>
        </Badge>
        player4
        <Slider v-model="value4"></Slider>
      </div>
    </div>
  </div>
</template>
<script>
  import {Pls} from '../js/pls'
  export default {
    data () {
      return {
        contractAddr: '0x2be23239A93D8Ef827E9a80E2B1a6eef271F9932',
        tokenAddr: '0x967ba827EBD984b99e5df7c4098d43Bb21bED34f',
        account: '',
        value1: 0,
        value2: 0,
        value3: 0,
        value4: 0
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
          console.log(pls.calAbi())
        }).catch(err => {
          console.log(`error is ${err}`)
        });
      },
      refreshAccounts: function () {
        pls.getAccounts((err, accounts) => {
          if (err || !accounts || !accounts.length) {
            setTimeout(this.refreshAccounts, 1000);
          } else {
            this.account = accounts[0]
            console.log('current account ', accounts[0])
          }
        });
      },
      bet: function () {
        pls.joinBet(this.account)
      }
    },
    created(){
      this.init()
    }
  }
</script>
