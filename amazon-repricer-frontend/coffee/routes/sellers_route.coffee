utils = require('../utils/utils')

SellersRoute = Ember.Route.extend({
  model: () ->
    utils.get_url('http://' + utils.BACKEND_URL + '/manufacturer_list')
    .then(
      (succ_ret) ->
        parsedResult = $.parseJSON(succ_ret)

        debugger
        return {
          sellerNames: parsedResult
        }
      (fail_ret) ->
        console.log('FAILURE IN SELLERS_ROUTE')
    )
})

module.exports = SellersRoute