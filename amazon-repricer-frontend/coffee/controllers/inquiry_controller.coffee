utils = require('../utils/utils')
ResultSetController = require('./result_set_controller')

InquiryController = ResultSetController.extend(
    selectedCategory: 'Laptop and Netbook Computer Batteries'
    categories: ['Laptop and Netbook Computer Batteries']

    pagesToReturn: ''

    selectedCountry: 'USA'
    countries: ['USA', 'UK', 'Canada']

    searchPhrases: ''

    isRunningQuery: false

    threeCell: ''
    fourCell: ''
    sixCell: ''
    eightCell: ''
    nineCell: ''
    twelveCell: ''

    threeCellOriginal: ''
    fourCellOriginal: ''
    sixCellOriginal: ''
    eightCellOriginal: ''
    nineCellOriginal: ''
    twelveCellOriginal: ''

    minPrices: (->
      {
        '3C': @get('threeCell')
        '4C': @get('fourCell')
        '6C': @get('sixCell')
        '8C': @get('eightCell')
        '9C': @get('nineCell')
        '12C': @get('twelveCell')

        '3CO': @get('threeCellOriginal')
        '4CO': @get('fourCellOriginal')
        '6CO': @get('sixCellOriginal')
        '8CO': @get('eightCellOriginal')
        '9CO': @get('nineCellOriginal')
        '12CO': @get('twelveCellOriginal')

        'minPrice': @get('minimumPrice')
        'discountPercent': @get('discountPercent')
      }
    ).property('threeCell', 'fourCell', 'sixCell', 'eightCell',
      'nineCell', 'twelveCell', 'threeCellOriginal', 'fourCellOriginal',
      'sixCellOriginal', 'eightCellOriginal', 'nineCellOriginal',
      'twelveCellOriginal', 'minimumPrice', 'discountPercent')

    # Small hack here to be able to call this from within another context
    updateminPrices: ((topContext = this) ->
      return unless topContext.get('resultSetName') isnt ''
      console.log('UPDATING BATTERY PRICES!')
      sku_prefix = if topContext.get('skuPrefix') then topContext.get('skuPrefix') else topContext.get('DEFAULT_SKU_PREFIX')
      utils.upload_data_promise('http://' + utils.BACKEND_URL + '/update_form_fields/' + topContext.get('resultSetName'),
        {
          min_prices: topContext.get('minPrices')
          sku_prefix: sku_prefix
          discount_percent: topContext.get('discountPercent')
          minimum_price: topContext.get('minimumPrice')
        }
      ).then(
        (succ_ret) ->
          console.log(succ_ret)
          console.log('SUCCESS!')
        (err_ret) ->
          console.log(err_ret)
          console.log('ERROR')
      )
    ).observes('minPrices')

    resultSetName: ''
    enteredName: ''
    placeHolderName: ''
    noNewSaveNameAvailable: (->
        resultSetName = @get('resultSetName')
        enteredName = @get('enteredName')
        placeHolderName = @get('placeHolderName')

        if enteredName isnt ''
          return resultSetName is enteredName

        return resultSetName is placeHolderName
    ).property('resultSetName', 'enteredName', 'placeHolderName')

    actions:
        searchButtonPressed: (->
            debugger
            @get('minPrices')
            topContext = this
            if topContext.get('isRunningQuery')
                alert('You can only run one query at a time. Wait for the last one to finish or load a new page.')
                return
            topContext.set('isRunningQuery', true)
            topContext.set('percentOfPagesFetched', 0)

            # Run a ton of queries asynchronously.
            _setTimeRemaining = (startTime, numRequestsReturned, numRequestsToMake) ->
                secondsRemaining = (((Date.now() - startTime) / numRequestsReturned) * (numRequestsToMake - numRequestsReturned) / (1000))
                if secondsRemaining <= 60
                    topContext.set('timeRemaining', 'Time remaining: ' + secondsRemaining.toFixed(0) + ' seconds.')
                else
                    topContext.set('timeRemaining', 'Time remaining: ' + (secondsRemaining / 60).toFixed(0) + ' minutes.')

            _parseResponses = (responseList) ->
                # Use JQuery to pull out the parts we care about.
                topContext.set('percentOfPagesFetched', 0)
                chunkSize = 2
                responseStartIndex = 0
                itemList = []
                topContext.set('lineAboveProgressBar', 'Parsing pages: ' + responseStartIndex + ' of ' + responseList.length)
                topContext.set('timeRemaining', 'Time remaining: ?')
                startTime = Date.now()
                return new Promise(
                    (resolve, reject) ->
                        processResponsesEfficiently = () ->
                            endIndex = Math.min(responseStartIndex + chunkSize, responseList.length)
                            for index in [responseStartIndex...endIndex]
                                responseDom = document.createElement('div')
                                responseDom.innerHTML = responseList[index]
                                for currentDiv, i in responseDom.querySelectorAll('li.s-result-item')
                                    continue unless currentDiv
                                    currentItem = {}

                                    currentItem['rank'] = currentDiv.getAttribute('id')
                                    if currentItem.rank isnt null
                                      currentItem.rank = Number(currentItem.rank.replace('result_', ''))
                                    else
                                      currentItem.rank = 999999 # If the item doesn't have a rank, just give it a large one so it appears at the bottom..
                                    currentItem['asin'] = currentDiv.getAttribute('data-asin')

                                    url = currentDiv.querySelector('.s-access-detail-page')
                                    currentItem['url'] = if url then url.getAttribute('href') else null

                                    title = currentDiv.querySelector('.s-access-detail-page')
                                    currentItem['title'] = if title then title.getAttribute('title') || title.innerText else null

                                    imageUrl = currentDiv.querySelector('.s-access-image')
                                    currentItem['imageUrl'] =  if imageUrl then imageUrl.getAttribute('src') else null

                                    firstPrice = currentDiv.querySelectorAll('.a-color-price')
                                    if firstPrice.length > 0
                                        currentItem['price'] = firstPrice[0].innerText
                                    else
                                        currentItem['price'] = null

                                    rating = currentDiv.querySelector('.a-icon.a-icon-star .a-icon-alt')?.innerText

                                    itemList.push(currentItem)
                                responseStartIndex += 1
                            topContext.set('lineAboveProgressBar', 'Parsing pages: ' + responseStartIndex + ' of ' + responseList.length)
                            _setTimeRemaining(startTime, responseStartIndex, responseList.length)
                            topContext.set('percentOfPagesFetched', (responseStartIndex / responseList.length) * 100)
                            if responseStartIndex < responseList.length
                                setTimeout(processResponsesEfficiently, 25)
                            else
                                # Remove duplicates.
                                asins = {}
                                finalItemList = []

                                for item in itemList
                                  unless asins[item.asin]
                                    finalItemList.push(item)
                                  asins[item.asin] = true

                                finalItemList.sort((itemA, itemB) -> return itemA.rank - itemB.rank)

                                debugger
                                resolve(finalItemList)
                        processResponsesEfficiently()
                 )

            pagesToReturn = if topContext.pagesToReturn is '' then 1 else parseInt(topContext.pagesToReturn)
            searchPhrases = topContext.searchPhrases.split('\n').filter((w) -> return w isnt '')
            selectedCountry = topContext.selectedCountry
            amazon_requests_promise = new Promise(
                (resolve, reject) ->
                    numRequestsToMake = searchPhrases.length * pagesToReturn
                    numRequestsReturned = 0
                    requestDataToReturn = []

                    if searchPhrases.length is 0
                        topContext.set('isRunningQuery', false)
                        return

                    topContext.set('lineAboveProgressBar', 'Fetching pages: ' + numRequestsReturned + ' of ' + numRequestsToMake)
                    topContext.set('timeRemaining', 'Time remaining: ?')
                    startTime = Date.now()
                    for phrase in searchPhrases
                        for page in [1..pagesToReturn]
                            if selectedCountry is 'Canada'
                                url = "http://www.amazon.ca/s/ref=nb_sb_noss_2?url=node%3D3341338011&field-keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;
                            else if selectedCountry is 'UK'
                                url = "http://www.amazon.co.uk/s/ref=sr_nr_n_6?rh=n%3A340831031%2Cn%3A430485031%2Ck%3Ahp&keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;
                            else
                                url = "http://www.amazon.com/s/?rh=n:720576&field-keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;

                            console.log(numRequestsToMake)
                            console.log(url)
                            utils.get_url(url).then(
                                (succ_data) ->
                                    topContext.set('lineAboveProgressBar', 'Fetching pages: ' + numRequestsReturned + ' of ' + numRequestsToMake)
                                    _setTimeRemaining(startTime, numRequestsReturned, numRequestsToMake)
                                    numRequestsReturned += 1
                                    topContext.set('percentOfPagesFetched', (numRequestsReturned / numRequestsToMake) * 100)

                                    console.log(numRequestsReturned + ' ' + numRequestsToMake)
                                    requestDataToReturn.push(succ_data)
                                    if numRequestsReturned is numRequestsToMake
                                        resolve(requestDataToReturn)
                                    console.log('SUCCESS')
                                    return succ_data
                                (err_data) ->
                                    numRequestsReturned += 1
                                    topContext.set('percentOfPagesFetched', (numRequestsReturned / numRequestsToMake) * 100)

                                    if numRequestsReturned is numRequestsToMake
                                        resolve(requestDataToReturn)
                                    console.log('ERROR')
                                    return err_data
                            )
            )

            # This is where the magic happens
            amazon_requests_promise.then(
                (responseList) ->
                    # Process the results here.
                    _parseResponses(responseList)
            ).then(
                (finalCleanedList) ->
                    for item, i in finalCleanedList
                      finalCleanedList[i]['itemIndex'] = i
                    topContext.set('finalCleanedList', finalCleanedList)
                    topContext.set('lineAboveProgressBar', 'Finished.')
                    topContext.set('timeRemaining', '')
                    topContext.set('isRunningQuery', false)

                    topContext.set('placeHolderName', 'INQUIRY_' + searchPhrases[0].split(' ').join('_') + '_'+
                      new Date().toString().split(' ').join('_'))
                    topContext.set('resultSetName', '')
                    topContext._setPage(0)
            )
        )

        saveButtonPressed: (->
            # TODO(nadera): fix so that renaming results doesn't screw you over.
            topContext = this

            finalCleanedList = topContext.get('finalCleanedList')
            unless finalCleanedList?
              return

            if topContext.get('enteredName') is ''
              topContext.set('resultSetName', topContext.get('placeHolderName'))
            else
              topContext.set('resultSetName', topContext.get('enteredName'))

            utils.upload_data_promise('http://' + utils.BACKEND_URL + '/create_results', {
                result_set_name: topContext.get('resultSetName')
                results: topContext.get('finalCleanedList')
                min_prices: @get('minPrices')
              }
            ).then(
                (succ_ret) ->
                    topContext.get('updateminPrices')(topContext)
                    console.log(succ_ret)
                    console.log('SUCCESS!')
                (err_ret) ->
                    topContext.set('resultSetName', '')
                    console.log(err_ret)
                    console.log('ERROR')
            )
        )
)

module.exports = InquiryController