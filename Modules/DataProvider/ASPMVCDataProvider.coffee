define ->

  class DataProvider

    onFlatData: (data) ->
      for own prop of data
        if !(data[prop] instanceof Date) and (typeof data[prop] == "object" or Array.isArray data[prop])
            delete data[prop]
      DataProvider.flatDate data
      data

    @flatDate: (data) ->
      #though in this instance object is flat in derived it could be not, so recursive
      for own prop of data
        if data[prop] instanceof Date
          data[prop] = data[prop].toUTCString()
        else if typeof data[prop] == "object"
          DataProvider.flatDate data[prop]
        else if Array.isArray data[prop]
          DataProvider.flatDate d for d in data[prop]

    _getActionUrl: (resource, action) ->
        "/" + resource + "/" + action.charAt(0).toUpperCase() + action.slice(1)

    _handleResult: (resp, res, done) ->
      if res == "error"
        done code : resp.status, message : resp.statusText
      else if resp.errors or resp.error
        done code : 500, message : (if resp.error then resp.error else "Ошибка выполнения"), errors : resp.errors
      else
        done null, resp

    getUrl: (resource, action, data) ->
      @_getActionUrl(resource, action) + "/" + data.Id

    get: (resource, filter, done) ->
      $.get(@_getActionUrl(resource, "index") + "Json", filter)
        .always (resp, res) => @_handleResult resp, res, done

    getNew: (resource, parentData, done) ->
      $.post(@_getActionUrl(resource, "getNew") + "Json", Id : (if parentData then parentData.Id else null))
        .always (resp, res) ->
          if res == "error"
            done code : resp.status, message : resp.statusText
          else
            done null, resp

    create: (resource, data, done) ->
      data = @onFlatData data
      $.post(@_getActionUrl(resource, "create") + "Json", data)
        .always (resp, res) => @_handleResult resp, res, done

    update: (resource, data, done) ->
      data = @onFlatData data
      $.post(@_getActionUrl(resource, "edit") + "Json", data)
        .always (resp, res) => @_handleResult resp, res, done

    delete: (resource, data, done) ->
      $.post(@_getActionUrl(resource, "delete") + "Json", Id : data.Id)
        .always (resp, res) => @_handleResult resp, res, done

    action: (resource, act, data, done) ->
      data = @onFlatData data
      $.post(@_getActionUrl(resource, act) + "Json", data)
        .always (resp, res) => @_handleResult resp, res, done
