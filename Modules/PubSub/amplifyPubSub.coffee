define ->

  pub: (target, topic, data) ->
    amplify.publish "#{target}_#{topic}", data

  sub: (target, topic, callback) ->

    amplify.subscribe "#{target}_#{topic}", callback
