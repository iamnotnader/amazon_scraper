// Generated by CoffeeScript 1.8.0
(function() {
  var ListingsListView;

  ListingsListView = Ember.View.extend({
    templateName: 'listings_list',
    itemListHasChanged: (function() {
      return this.rerender();
    }).observes('controller.listedItems')
  });

  module.exports = ListingsListView;

}).call(this);
