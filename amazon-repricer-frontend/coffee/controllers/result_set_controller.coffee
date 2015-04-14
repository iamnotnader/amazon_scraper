utils = require('../utils/utils')

RESULTS_PER_PAGE = 100

ResultSetController = Ember.ObjectController.extend(
  DEFAULT_SKU_PREFIX: 'TECHROVER_SKU'

  finalCleanedList: []
  resultSetName: ''
  minPrices: {}

  skuPrefix: ''
  discountPercent: ''
  minimumPrice: ''

  percentOfPagesFetched: 0
  lineAboveProgressBar: ''
  timeRemaining: ''

  pages: (->
    finalCleanedList = @get('finalCleanedList')
    return unless finalCleanedList?

    pages = []
    page = []
    for item, i in finalCleanedList
      if i % RESULTS_PER_PAGE is 0 and i isnt 0
        pages.push(page)
        page = []
      page.push(item)

    if page.length > 0
      pages.push(page)

    return pages
  ).property('finalCleanedList')

  currentPageIndex: 0

  _setPage: (newPageIndex) ->
    console.log('NEW PAGE INDEX: ' + newPageIndex)
    @set('currentPageIndex', Number(newPageIndex))
    currentPageItems = @get('currentPage')

    topContext = this

    _parseDeepPage = (html_page) ->
      responseDom = document.createElement('div')
      responseDom.innerHTML = html_page

      ret = {}
      ret.technicalDetails = responseDom.querySelector('#technical-data .content ul')
      ret.technicalDetails = if ret.technicalDetails then ret.technicalDetails.outerHTML.trim() else 'NONE'

      ret.productDescription = responseDom.querySelector('#detail-bullets ul')
      ret.productDescription = if ret.productDescription then ret.productDescription.outerHTML.trim() else 'NONE.'

      ret.manufacturer = responseDom.querySelector('#brandByline_feature_div a ')
      ret.manufacturerLink = if ret.manufacturer then 'http://www.amazon.com/' + ret.manufacturer.getAttribute('href') else ''

      ret.manufacturer = if ret.manufacturer then ret.manufacturer.innerText else 'NONE'

      return ret

    # NOW GET PRODUCT DETAILS AND SHIT!
    # For each thing in finalCleanedList, kick off an ajax call..
    # Remember: this.set('finalCleanedList', this.get('finalCleanedList'))
    # In order to get the list to update properly.
    thingsToProcess = []
    thingsProcessed = 0
    topContext.set('lineAboveProgressBar', 'Fetching product info: ' + thingsProcessed + ' of ' + currentPageItems.length)
    topContext.set('timeRemaining', 'Time remaining: ?')
    startTime = Date.now()

    # Set the time remaining before all product info is fetched.
    _setTimeRemaining = (startTime, numRequestsReturned, numRequestsToMake) ->
      secondsRemaining = (((Date.now() - startTime) / numRequestsReturned) * (numRequestsToMake - numRequestsReturned) / (1000))
      if secondsRemaining <= 60
        topContext.set('timeRemaining', 'Time remaining: ' + secondsRemaining.toFixed(0) + ' seconds.')
      else
        topContext.set('timeRemaining', 'Time remaining: ' + (secondsRemaining / 60).toFixed(0) + ' minutes.')

    processProductInfoEfficiently = () ->
      console.log('PROCESSING')
      if thingsProcessed is currentPageItems.length
        console.log('RETURNING ' + thingsProcessed)
        topContext.set('lineAboveProgressBar', '') # This is how we get rid of the progress bar.
        topContext.propertyDidChange('finalCleanedList')
        return

      if thingsToProcess.length > 0
        # process one of them and remove it
        thing = thingsToProcess.pop()

        succ_data = thing[0]
        index = thing[1]

        payload = _parseDeepPage(succ_data)
        console.log(payload)
        for key, value of payload
          currentPageItems[index][key] = value

        thingsProcessed += 1
        console.log("Processed " + thingsProcessed + " things.")

        topContext.set('lineAboveProgressBar', 'Fetching product info: ' + thingsProcessed + ' of ' + currentPageItems.length)
        _setTimeRemaining(startTime, thingsProcessed, currentPageItems.length)
        topContext.set('percentOfPagesFetched', (thingsProcessed / currentPageItems.length) * 100)
      setTimeout(processProductInfoEfficiently, 0)

    for elem, i in currentPageItems
      temp = (index) ->
        console.log('http://www.amazon.com/dp/' + currentPageItems[index].asin)
        utils.get_url('http://www.amazon.com/dp/' + currentPageItems[index].asin).then(
          (succ_data) ->
            thingsToProcess.push([succ_data, index])
        )
      temp(i)

    processProductInfoEfficiently()

  currentPage: (->
    pages = @get('pages')
    currentPageIndex = @get('currentPageIndex')
    return unless (pages? and currentPageIndex?)

    return pages[currentPageIndex]
  ).property('pages', 'currentPageIndex')

  actions:
    changePage: (newPageIndex) ->
      @_setPage(newPageIndex)

    listButtonPressed: (batteryType, itemIndex, manufacturer, manufacturerLink) ->
      if @get('resultSetName') is ''
        alert('You must save your results before you can start adding listings.')
        return

      unless manufacturer?
        alert('You must wait until a manufacturer is available before you can list.')
        return

      console.log('RESULT SET NAME: ' + @get('resultSetName'))
      # List the item here..
      utils.upload_data_promise('http://' + utils.BACKEND_URL + '/add_listing_to/' + @get('resultSetName'),
        {
          batteryType: batteryType
          listing_index: itemIndex
          manufacturer: manufacturer
          manufacturerLink: manufacturerLink
        }
      ).then(
        (succ_ret) ->
          console.log(succ_ret)
          console.log('SUCCESS!')
        (err_ret) ->
          console.log(err_ret)
          console.log('ERROR')
      )
)

module.exports = ResultSetController