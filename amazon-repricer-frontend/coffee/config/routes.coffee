App = require('./app');

App.Router.map(() ->
  @route('inquiry')
  @route('listings')
  @route('sellers')
  @route('results')
)

