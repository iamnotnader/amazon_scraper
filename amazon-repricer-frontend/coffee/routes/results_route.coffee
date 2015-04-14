utils = require('../utils/utils')

ResultsRoute = Ember.Route.extend({
  model: () ->
    utils.get_url('http://' + utils.BACKEND_URL + '/result_set_names')
    .then(
      (ret) ->
        parsedResult = $.parseJSON(ret)

        return {
          resultSetNames: parsedResult
          selectedResult: if parsedResult.length > 0 then parsedResult[0] else ''
        }
    )
})

module.exports = ResultsRoute