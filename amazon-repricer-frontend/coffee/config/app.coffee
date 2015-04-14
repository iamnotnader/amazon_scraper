# require other, dependencies here, ie:
# #require('./vendor/moment');

require('../vendor/jquery');
require('../vendor/handlebars');
require('../vendor/ember');
require('../vendor/ember-data'); # delete if you don't want ember-data
require('../vendor/list-view-latest');
require('../vendor/bootstrap.min');

App = Ember.Application.create();
App.Store = require('./store'); # delete if you don't want ember-data

module.exports = App;