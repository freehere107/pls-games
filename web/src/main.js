// The Vue build version to load with the `import` command
// (runtime-only or standalone) has been set in webpack.base.conf with an alias.
import Vue from 'vue'
import App from './App'
import iView from 'iview'
import router from './router'
import 'iview/dist/styles/iview.css'

import axios from 'axios'
Vue.prototype.axios = axios
Vue.config.productionTip = false

/* eslint-disable no-new */
Vue.use(iView)

new Vue({
  el: '#app',
  router,
  template: '<App/>',
  components: { App }
})
