define ->

  _flatData = (data) ->
    for own prop of data
      if typeof data[prop] == "object"
        if data[prop] instanceof Date
          data[prop] = data[prop].toUTCString()
        else
          delete data[prop]
    data

  _getActionUrl = (resource, action) ->
      "/" + resource + "/" + action.charAt(0).toUpperCase() + action.slice(1)

  _handleResult = (resp, res, done) ->
    if res == "error"
      done code : resp.status, message : resp.statusText
    else if resp.errors or resp.error
      done code : 500, message : (if resp.error then resp.error else "Ошибка выполнения"), errors : resp.errors
    else
      done null, resp

  getUrl: (resource, action, data) ->
    _getActionUrl(resource, action) + "/" + data.Id

  get: (resource, filter, done) ->
    $.get(_getActionUrl(resource, "index") + "Json", filter)
      .always (resp, res) -> _handleResult resp, res, done

  getNew: (resource, parentData, done) ->
    $.post(_getActionUrl(resource, "getNew") + "Json", Id : (if parentData then parentData.Id else null))
      .always (resp, res) ->
        if res == "error"
          done code : resp.status, message : resp.statusText
        else
          done null, resp

  create: (resource, data, done) ->
    data = _flatData data
    $.post(_getActionUrl(resource, "create") + "Json", data)
      .always (resp, res) -> _handleResult resp, res, done

  update: (resource, data, done) ->
    data = _flatData data
    $.post(_getActionUrl(resource, "edit") + "Json", data)
      .always (resp, res) -> _handleResult resp, res, done

  delete: (resource, data, done) ->
    $.post(_getActionUrl(resource, "delete") + "Json", Id : data.Id)
      .always (resp, res) -> _handleResult resp, res, done

  action: (resource, act, data, done) ->
    data = _flatData data
    $.post(_getActionUrl(resource, act) + "Json", data)
      .always (resp, res) -> _handleResult resp, res, done
