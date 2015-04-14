utils = require('../utils/utils')
ResultSetController = require('./result_set_controller')

ResultsController = ResultSetController.extend(
  selectedResultsMatchDisplayed: (->
    return @get('resultSetName') is @get('selectedResult')
  ).property('resultSetName', 'selectedResult')

  resultSetName: ''

  minPrices: {
    '3C': ''
    '4C': ''
    '6C': ''
    '8C': ''
    '9C': ''
    '12C': ''

    '3CO': ''
    '4CO': ''
    '6CO': ''
    '8CO': ''
    '9CO': ''
    '12CO': ''
  }

  actions:
    showResultsButtonPressed: (->
      topContext = this

      @set('resultSetName', @get('selectedResult'))
      console.log('SHOW RESULT PRESSED')
      utils.get_url('http://' + utils.BACKEND_URL + '/results_for_name/' + @get('resultSetName'))
      .then(
        (ret) ->
          parsedResult = $.parseJSON(ret)
          topContext.set('finalCleanedList', parsedResult[0].results)
          topContext.set('minPrices', parsedResult[0].min_prices)
          topContext.set('skuPrefix', parsedResult[0].sku_prefix)
          topContext.set('discountPercent', parsedResult[0].discount_percent)
          topContext.set('minimumPrice', parsedResult[0].minimum_price)

          topContext._setPage(0)
      )
    )

    deleteButtonPressed: (->
      alert('This button is not yet implemented.')
      console.log('DELETE RESULT PRESSED')
      console.log(@get('selectedResult'))
    )
)

module.exports = ResultsController