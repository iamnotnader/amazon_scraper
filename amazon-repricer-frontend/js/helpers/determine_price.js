// Generated by CoffeeScript 1.8.0
(function() {
  var utils;

  utils = require('../utils/utils');

  Ember.Handlebars.helper('determinePrice', function(batteryType, minPrices, price, discountPercent) {
    if (price === null) {
      return minPrices['batteryType'];
    }
    return '$' + utils.determine_price(batteryType, minPrices, Number(price.trim().replace('$', '')), Number(discountPercent)).toFixed(2);
  });

}).call(this);
