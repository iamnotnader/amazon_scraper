ListingsListView = Ember.View.extend(
    templateName: 'listings_list'


    itemListHasChanged: (->
      @rerender()
    ).observes('controller.listedItems')
)

module.exports = ListingsListView