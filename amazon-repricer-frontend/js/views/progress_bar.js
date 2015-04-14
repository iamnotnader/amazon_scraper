// Generated by CoffeeScript 1.8.0
(function() {
  var ProgressBar;

  ProgressBar = Ember.View.extend({
    classNames: ['progress'],
    template: (function() {
      return '<div class="progress-bar" role="progressbar" aria-valuenow="60" aria-valuemin="0" aria-valuemax="100" style="width: 0%; transition: none;"> <div class=percentInside style="color: black; margin: 0px 5px;">0%</div> </div>';
    }),
    percent: 0,
    percentDidChange: (function() {
      var percent;
      percent = this.get('percent' || 0);
      this.$('.progress-bar').css('width', percent + '%');
      this.$('div.percentInside').html(percent.toFixed(0) + '%');
      if (percent === 0) {
        return this.$('div.percentInside').css('margin', '0px', '5px');
      }
    }).observes('percent')
  });

  module.exports = ProgressBar;

}).call(this);