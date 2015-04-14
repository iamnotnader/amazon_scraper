InquiryListView = Ember.ListView.extend({
  height: 500
  rowHeight: 400
  itemViewClass: Ember.ListItemView.extend({templateName: "inquiry_row_item"})
})

module.exports = InquiryListView

