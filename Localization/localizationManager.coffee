define ->

  setup : (local, done) ->

    require ["Ural/Localization/#{local}/controller.text"], (controllerText) ->
      window.localization =
        controller :
          text : controllerText
      if done then done()


