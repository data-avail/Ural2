define ->

  _providers = []

  set : (name, provider, isDefault) ->
    isDefault = true ? isDefault == undefined and _providers.length == 0
    _providers[name] = provider
    if isDefault
      _providers["__DEF__"] = provider

  get : (name) ->
    name = "__DEF__" if !name
    _providers[name]