// Generated by CoffeeScript 1.8.0
(function() {
  var InquiryController, ResultSetController, utils;

  utils = require('../utils/utils');

  ResultSetController = require('./result_set_controller');

  InquiryController = ResultSetController.extend({
    selectedCategory: 'Laptop and Netbook Computer Batteries',
    categories: ['Laptop and Netbook Computer Batteries'],
    pagesToReturn: '',
    selectedCountry: 'USA',
    countries: ['USA', 'UK', 'Canada'],
    searchPhrases: '',
    isRunningQuery: false,
    threeCell: '',
    fourCell: '',
    sixCell: '',
    eightCell: '',
    nineCell: '',
    twelveCell: '',
    threeCellOriginal: '',
    fourCellOriginal: '',
    sixCellOriginal: '',
    eightCellOriginal: '',
    nineCellOriginal: '',
    twelveCellOriginal: '',
    minPrices: (function() {
      return {
        '3C': this.get('threeCell'),
        '4C': this.get('fourCell'),
        '6C': this.get('sixCell'),
        '8C': this.get('eightCell'),
        '9C': this.get('nineCell'),
        '12C': this.get('twelveCell'),
        '3CO': this.get('threeCellOriginal'),
        '4CO': this.get('fourCellOriginal'),
        '6CO': this.get('sixCellOriginal'),
        '8CO': this.get('eightCellOriginal'),
        '9CO': this.get('nineCellOriginal'),
        '12CO': this.get('twelveCellOriginal'),
        'minPrice': this.get('minimumPrice'),
        'discountPercent': this.get('discountPercent')
      };
    }).property('threeCell', 'fourCell', 'sixCell', 'eightCell', 'nineCell', 'twelveCell', 'threeCellOriginal', 'fourCellOriginal', 'sixCellOriginal', 'eightCellOriginal', 'nineCellOriginal', 'twelveCellOriginal', 'minimumPrice', 'discountPercent'),
    updateminPrices: (function(topContext) {
      var sku_prefix;
      if (topContext == null) {
        topContext = this;
      }
      if (topContext.get('resultSetName') === '') {
        return;
      }
      console.log('UPDATING BATTERY PRICES!');
      sku_prefix = topContext.get('skuPrefix') ? topContext.get('skuPrefix') : topContext.get('DEFAULT_SKU_PREFIX');
      return utils.upload_data_promise('http://' + utils.BACKEND_URL + '/update_form_fields/' + topContext.get('resultSetName'), {
        min_prices: topContext.get('minPrices'),
        sku_prefix: sku_prefix,
        discount_percent: topContext.get('discountPercent'),
        minimum_price: topContext.get('minimumPrice')
      }).then(function(succ_ret) {
        console.log(succ_ret);
        return console.log('SUCCESS!');
      }, function(err_ret) {
        console.log(err_ret);
        return console.log('ERROR');
      });
    }).observes('minPrices'),
    resultSetName: '',
    enteredName: '',
    placeHolderName: '',
    noNewSaveNameAvailable: (function() {
      var enteredName, placeHolderName, resultSetName;
      resultSetName = this.get('resultSetName');
      enteredName = this.get('enteredName');
      placeHolderName = this.get('placeHolderName');
      if (enteredName !== '') {
        return resultSetName === enteredName;
      }
      return resultSetName === placeHolderName;
    }).property('resultSetName', 'enteredName', 'placeHolderName'),
    actions: {
      searchButtonPressed: (function() {
        debugger;
        var amazon_requests_promise, pagesToReturn, searchPhrases, selectedCountry, topContext, _parseResponses, _setTimeRemaining;
        this.get('minPrices');
        topContext = this;
        if (topContext.get('isRunningQuery')) {
          alert('You can only run one query at a time. Wait for the last one to finish or load a new page.');
          return;
        }
        topContext.set('isRunningQuery', true);
        topContext.set('percentOfPagesFetched', 0);
        _setTimeRemaining = function(startTime, numRequestsReturned, numRequestsToMake) {
          var secondsRemaining;
          secondsRemaining = ((Date.now() - startTime) / numRequestsReturned) * (numRequestsToMake - numRequestsReturned) / 1000.;
          if (secondsRemaining <= 60) {
            return topContext.set('timeRemaining', 'Time remaining: ' + secondsRemaining.toFixed(0) + ' seconds.');
          } else {
            return topContext.set('timeRemaining', 'Time remaining: ' + (secondsRemaining / 60).toFixed(0) + ' minutes.');
          }
        };
        _parseResponses = function(responseList) {
          var chunkSize, itemList, responseStartIndex, startTime;
          topContext.set('percentOfPagesFetched', 0);
          chunkSize = 2;
          responseStartIndex = 0;
          itemList = [];
          topContext.set('lineAboveProgressBar', 'Parsing pages: ' + responseStartIndex + ' of ' + responseList.length);
          topContext.set('timeRemaining', 'Time remaining: ?');
          startTime = Date.now();
          return new Promise(function(resolve, reject) {
            var processResponsesEfficiently;
            processResponsesEfficiently = function() {
              var asins, currentDiv, currentItem, endIndex, finalItemList, firstPrice, i, imageUrl, index, item, rating, responseDom, title, url, _i, _j, _k, _len, _len1, _ref, _ref1;
              endIndex = Math.min(responseStartIndex + chunkSize, responseList.length);
              for (index = _i = responseStartIndex; responseStartIndex <= endIndex ? _i < endIndex : _i > endIndex; index = responseStartIndex <= endIndex ? ++_i : --_i) {
                responseDom = document.createElement('div');
                responseDom.innerHTML = responseList[index];
                _ref = responseDom.querySelectorAll('li.s-result-item');
                for (i = _j = 0, _len = _ref.length; _j < _len; i = ++_j) {
                  currentDiv = _ref[i];
                  if (!currentDiv) {
                    continue;
                  }
                  currentItem = {};
                  currentItem['rank'] = currentDiv.getAttribute('id');
                  if (currentItem.rank !== null) {
                    currentItem.rank = Number(currentItem.rank.replace('result_', ''));
                  } else {
                    currentItem.rank = 999999;
                  }
                  currentItem['asin'] = currentDiv.getAttribute('data-asin');
                  url = currentDiv.querySelector('.s-access-detail-page');
                  currentItem['url'] = url ? url.getAttribute('href') : null;
                  title = currentDiv.querySelector('.s-access-detail-page');
                  currentItem['title'] = title ? title.getAttribute('title') || title.innerText : null;
                  imageUrl = currentDiv.querySelector('.s-access-image');
                  currentItem['imageUrl'] = imageUrl ? imageUrl.getAttribute('src') : null;
                  firstPrice = currentDiv.querySelectorAll('.a-color-price');
                  if (firstPrice.length > 0) {
                    currentItem['price'] = firstPrice[0].innerText;
                  } else {
                    currentItem['price'] = null;
                  }
                  rating = (_ref1 = currentDiv.querySelector('.a-icon.a-icon-star .a-icon-alt')) != null ? _ref1.innerText : void 0;
                  itemList.push(currentItem);
                }
                responseStartIndex += 1;
              }
              topContext.set('lineAboveProgressBar', 'Parsing pages: ' + responseStartIndex + ' of ' + responseList.length);
              _setTimeRemaining(startTime, responseStartIndex, responseList.length);
              topContext.set('percentOfPagesFetched', (responseStartIndex / responseList.length) * 100);
              if (responseStartIndex < responseList.length) {
                return setTimeout(processResponsesEfficiently, 25);
              } else {
                asins = {};
                finalItemList = [];
                for (_k = 0, _len1 = itemList.length; _k < _len1; _k++) {
                  item = itemList[_k];
                  if (!asins[item.asin]) {
                    finalItemList.push(item);
                  }
                  asins[item.asin] = true;
                }
                finalItemList.sort(function(itemA, itemB) {
                  return itemA.rank - itemB.rank;
                });
                debugger;
                return resolve(finalItemList);
              }
            };
            return processResponsesEfficiently();
          });
        };
        pagesToReturn = topContext.pagesToReturn === '' ? 1 : parseInt(topContext.pagesToReturn);
        searchPhrases = topContext.searchPhrases.split('\n').filter(function(w) {
          return w !== '';
        });
        selectedCountry = topContext.selectedCountry;
        amazon_requests_promise = new Promise(function(resolve, reject) {
          var numRequestsReturned, numRequestsToMake, page, phrase, requestDataToReturn, startTime, url, _i, _len, _results;
          numRequestsToMake = searchPhrases.length * pagesToReturn;
          numRequestsReturned = 0;
          requestDataToReturn = [];
          if (searchPhrases.length === 0) {
            topContext.set('isRunningQuery', false);
            return;
          }
          topContext.set('lineAboveProgressBar', 'Fetching pages: ' + numRequestsReturned + ' of ' + numRequestsToMake);
          topContext.set('timeRemaining', 'Time remaining: ?');
          startTime = Date.now();
          _results = [];
          for (_i = 0, _len = searchPhrases.length; _i < _len; _i++) {
            phrase = searchPhrases[_i];
            _results.push((function() {
              var _j, _results1;
              _results1 = [];
              for (page = _j = 1; 1 <= pagesToReturn ? _j <= pagesToReturn : _j >= pagesToReturn; page = 1 <= pagesToReturn ? ++_j : --_j) {
                if (selectedCountry === 'Canada') {
                  url = "http://www.amazon.ca/s/ref=nb_sb_noss_2?url=node%3D3341338011&field-keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;
                } else if (selectedCountry === 'UK') {
                  url = "http://www.amazon.co.uk/s/ref=sr_nr_n_6?rh=n%3A340831031%2Cn%3A430485031%2Ck%3Ahp&keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;
                } else {
                  url = "http://www.amazon.com/s/?rh=n:720576&field-keywords=" + (phrase.split(' ').join('+')) + "&page=" + page;
                }
                console.log(numRequestsToMake);
                console.log(url);
                _results1.push(utils.get_url(url).then(function(succ_data) {
                  topContext.set('lineAboveProgressBar', 'Fetching pages: ' + numRequestsReturned + ' of ' + numRequestsToMake);
                  _setTimeRemaining(startTime, numRequestsReturned, numRequestsToMake);
                  numRequestsReturned += 1;
                  topContext.set('percentOfPagesFetched', (numRequestsReturned / numRequestsToMake) * 100);
                  console.log(numRequestsReturned + ' ' + numRequestsToMake);
                  requestDataToReturn.push(succ_data);
                  if (numRequestsReturned === numRequestsToMake) {
                    resolve(requestDataToReturn);
                  }
                  console.log('SUCCESS');
                  return succ_data;
                }, function(err_data) {
                  numRequestsReturned += 1;
                  topContext.set('percentOfPagesFetched', (numRequestsReturned / numRequestsToMake) * 100);
                  if (numRequestsReturned === numRequestsToMake) {
                    resolve(requestDataToReturn);
                  }
                  console.log('ERROR');
                  return err_data;
                }));
              }
              return _results1;
            })());
          }
          return _results;
        });
        return amazon_requests_promise.then(function(responseList) {
          return _parseResponses(responseList);
        }).then(function(finalCleanedList) {
          var i, item, _i, _len;
          for (i = _i = 0, _len = finalCleanedList.length; _i < _len; i = ++_i) {
            item = finalCleanedList[i];
            finalCleanedList[i]['itemIndex'] = i;
          }
          topContext.set('finalCleanedList', finalCleanedList);
          topContext.set('lineAboveProgressBar', 'Finished.');
          topContext.set('timeRemaining', '');
          topContext.set('isRunningQuery', false);
          topContext.set('placeHolderName', 'INQUIRY_' + searchPhrases[0].split(' ').join('_') + '_' + new Date().toString().split(' ').join('_'));
          topContext.set('resultSetName', '');
          return topContext._setPage(0);
        });
      }),
      saveButtonPressed: (function() {
        var finalCleanedList, topContext;
        topContext = this;
        finalCleanedList = topContext.get('finalCleanedList');
        if (finalCleanedList == null) {
          return;
        }
        if (topContext.get('enteredName') === '') {
          topContext.set('resultSetName', topContext.get('placeHolderName'));
        } else {
          topContext.set('resultSetName', topContext.get('enteredName'));
        }
        return utils.upload_data_promise('http://' + utils.BACKEND_URL + '/create_results', {
          result_set_name: topContext.get('resultSetName'),
          results: topContext.get('finalCleanedList'),
          min_prices: this.get('minPrices')
        }).then(function(succ_ret) {
          topContext.get('updateminPrices')(topContext);
          console.log(succ_ret);
          return console.log('SUCCESS!');
        }, function(err_ret) {
          topContext.set('resultSetName', '');
          console.log(err_ret);
          return console.log('ERROR');
        });
      })
    }
  });

  module.exports = InquiryController;

}).call(this);