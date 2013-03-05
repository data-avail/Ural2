define ->

  postbox = new ko.subscribable()

  pub: (target, topic, data) ->


  sub: (target, topic, callback) ->

    postbox.subscribe topic, callback
