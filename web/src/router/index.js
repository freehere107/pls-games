import Vue from 'vue'
import Router from 'vue-router'
import Pls from '@/components/pls'

Vue.use(Router)

export default new Router({
  routes: [
    {
      path: '/',
      name: 'HelloWorld',
      component: Pls
    }
  ]
})
