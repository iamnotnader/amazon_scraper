utils = require('../utils/utils')

Ember.Handlebars.helper('determinePrice', (batteryType, minPrices, price, discountPercent) ->
  if price is null
    return minPrices['batteryType']
  return '$' + utils.determine_price(batteryType, minPrices, Number(price.trim().replace('$', '')), Number(discountPercent)).toFixed(2)
)