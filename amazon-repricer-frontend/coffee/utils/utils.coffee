utils =
  get_url: (url) ->
    # Return a new promise.
    return new Promise(
      (resolve, reject) ->
        # Do the usual XHR stuff
        req = new XMLHttpRequest()
        req.open('GET', url)

        req.onload = () ->
          # This is called even on 404 etc so check the status
          if (req.status == 200)
            # Resolve the promise with the response text
            resolve(req.response);
          else
            # Otherwise reject with the status text which will hopefully be a meaningful error
            reject(Error(req.statusText))

        # Handle network errors
        req.onerror = () ->
          reject(Error("Network Error"))

        # Make the request
        req.send()
    )

  upload_data_promise: (url, data) ->
    console.log(data)
    console.log(JSON.stringify(data))
    $.ajax(
      url : url
      data: {json_str: JSON.stringify(data)}
      dataType: 'text'
      type: 'post'
      async: true
    )

  determine_price: (batteryType, minPrices, price, discountPercent) ->
    batteryLimit = if minPrices[batteryType] is '' then 0 else Number(minPrices[batteryType])
    price = price * (1 - discountPercent/100)
    return Math.max(batteryLimit, price)

  BACKEND_URL: "amazon-repricer-backend.herokuapp.com"#'0.0.0.0:5000'#


module.exports = utils