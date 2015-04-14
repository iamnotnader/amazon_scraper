utils = require('../utils/utils')
ResultsController = require('./results_controller')

ListingsController = ResultsController.extend(
  listedItems: []
  fetchingListedItems: true

  exportDisabled: (->
    return @get('resultSetName') is ''
  ).property('resultSetName')

  actions:
    showResultsButtonPressed: (->
      topContext = this

      topContext.set('resultSetName', topContext.get('selectedResult'))
      console.log('SHOW RESULT PRESSED')
      topContext.set('fetchingListedItems', true)
      utils.get_url('http://' + utils.BACKEND_URL + '/listed_items_for_result_set/' + @get('resultSetName'))
      .then(
        (succ_ret) ->
          parsedResult = $.parseJSON(succ_ret)
          topContext.set('minPrices', parsedResult[0].min_prices)
          topContext.set('skuPrefix', parsedResult[0].sku_prefix)
          topContext.set('discountPercent', parsedResult[0].discount_percent)
          topContext.set('minimumPrice', parsedResult[0].minimum_price)

          listedItemIndices = parsedResult[0].listed_items
          listedItems = []

          for item in listedItemIndices
            listingIndex = item.listing_index
            batteryType = item.batteryType
            manufacturer_id = item.manufacturer_id

            skuPrefix = topContext.get('skuPrefix')

            listedItems.push({
              asin: item.asin,
              sku: skuPrefix + '_' + batteryType + '_' + manufacturer_id + '_' + item.rank
              price: (utils.determine_price(batteryType, topContext.get('minPrices'), Number(item.price.trim().replace('$', '')), topContext.get('discountPercent'))).toFixed(2)
              listing_index: listingIndex
              battery_type: batteryType
            })

          topContext.set('listedItems', listedItems)
          topContext.set('fetchingListedItems', false)
        (err_ret) ->
          console.log('ERROR FETCHING LISTINGS!')
          topContext.set('fetchingListedItems', false)
      )
    )

    exportPressed: (->
      topContext = this

      if topContext.get('resultSetName') isnt topContext.get('selectedResult')
        # Fetch the listed items and display them to make it clear what we're exporting.
        topContext.send('showResultsButtonPressed')

      # Wait for the showResultsButtonPressed promise to return and populate
      # listedItems.
      waitForListedItems = () ->
        if topContext.get('fetchingListedItems')
          setTimeout(waitForListedItems, 100)
          return

        listedItems = topContext.get('listedItems')

        csvContent = "data:text/csv;charset=utf-8,"
        columnNames = "sku,product-id,product-id-type,price,item-condition,quantity,add-delete,will-ship-internationally,expedited-shipping,standard-plus,item-note,fulfillment-center-id,product-tax-code,leadtime-to-ship\n"

        csvContent += columnNames
        for item in listedItems
          csvContent += item.sku + ',' + item.asin + ',1,' + item.price + ',11,40,a,y,"Next, Second, Domestic, International",,"Brand New Compatible Battery, Superior Tech Rover Quality, 30-Day Any Reason Return Policy with Unmatched Tech Rover Customer Service! Buy with confidence from a knowledgeable US seller you can trust.",,,1\n'

        encodedUri = encodeURI(csvContent)
        link = document.createElement("a");
        link.setAttribute("href", encodedUri);
        link.setAttribute("download", topContext.get('resultSetName') + '.csv')

        link.click();

      waitForListedItems()
    )

    deleteEntry: ((sku) ->
      topContext = this
      listedItems = topContext.get('listedItems')
      indexToDelete = -1
      for item, i in listedItems
        if item.sku is sku
          indexToDelete = i
          break
      if indexToDelete isnt -1
        # Remove the listing from the db.
        utils.upload_data_promise('http://' + utils.BACKEND_URL + '/remove_listing_from/' + topContext.get('resultSetName'),
          {
            listing_index: listedItems[indexToDelete].listing_index
            battery_type: listedItems[indexToDelete].battery_type
          }
        ).then(
          (succ_ret) ->
            # Remove the listing from the view.
            listedItems.splice(indexToDelete, 1)
            topContext.propertyDidChange('listedItems')

            console.log(succ_ret)
            console.log('SUCCESS!')
          (err_ret) ->
            console.log(err_ret)
            console.log('ERROR')
        )
    )

)

module.exports = ListingsController