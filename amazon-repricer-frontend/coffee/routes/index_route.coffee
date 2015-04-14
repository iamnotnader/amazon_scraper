IndexRoute = Ember.Route.extend({
    beforeModel: () ->
        @transitionTo("inquiry")
})

module.exports = IndexRoute