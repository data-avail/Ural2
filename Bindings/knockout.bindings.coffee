
_updateAutocompleteFields = (viewModel, fields, item, isResetOnNull) ->
  for own field of fields
    if item and item.data
      viewModel[fields[field]] item.data[field]
    else if isResetOnNull
      viewModel[fields[field]] null

ko.bindingHandlers.autocomplete =

  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    opts = allBindingsAccessor().autocompleteOpts
    $(element).autocomplete
      source: ( request, response ) ->
        $.ajax
          url: opts.url
          data:
            Term: $(element).val()
          dataType: "json"
          success: (data) ->
            response(
              data.map (d) ->
                data: d
                label: if d.FullName then d.FullName else d.Name
                value: d.Name
                key: d.Name
              )
          minLength: 2
      select: (event, ui) ->
        console.log "select " + ui.item
        valueAccessor() ui.item.value
        _updateAutocompleteFields viewModel, opts.fields, ui.item, opts.resetRelatedFieldsOnNull
      change: (event, ui) ->
        console.log "change " + ui.item
        valueAccessor() $(element).val()
        _updateAutocompleteFields viewModel, opts.fields, ui.item, opts.resetRelatedFieldsOnNull

  update: (element, valueAccessor, allBindingsAccessor) ->
    opts = allBindingsAccessor().autocompleteOpts
    value = ko.utils.unwrapObservable valueAccessor()
    console.log "update " + value
    if $(element).val() != value
      $(element).val value

ko.bindingHandlers.datetime =

  init: (element, valueAccessor) ->
    #initialize datepicker with some optional options
    if valueAccessor().extend and valueAccessor().extend().rules
      dminRule = valueAccessor().extend().rules().filter((f) -> f.rule == "min")[0]
      minDate = moment(dminRule.params).toDate() if dminRule
      dmaxRule = valueAccessor().extend().rules().filter((f) -> f.rule == "max")[0]
      maxDate = moment(dmaxRule.params).toDate() if dmaxRule

    $(element).datepicker
       minDate: minDate
       maxDate: maxDate
       beforeShow: (el) ->
         return if $(el).attr('readonly') then false else true

    #handle the field changing
    ko.utils.registerEventHandler element, "change", ->
      observable = valueAccessor()
      date = $(element).datepicker "getDate"
      observable date

    #handle disposal (if KO removes by the template binding)
    ko.utils.domNodeDisposal.addDisposeCallback element, ->
      $(element).datepicker "destroy"

  update: (element, valueAccessor) ->
    value = ko.utils.unwrapObservable(valueAccessor())
    $(element).datepicker "setDate", if value then value else null
    valueAccessor()($(element).datepicker "getDate")

_setDate = (element, date, format) ->
  format ?= "DD MMMM YYYY"
  $(element).text if date then moment(date).format(format) else ""

ko.bindingHandlers.displaydate =
  init: (element, valueAccessor, allBindingsAccessor) ->
    option = allBindingsAccessor().ddateOpts
    format =  option.format if option
    valAccessor = valueAccessor()
    _setDate element, ko.utils.unwrapObservable(valAccessor), format
    valAccessor.subscribe (newValue) ->
      _setDate element, newValue, format

ko.bindingHandlers.validationCss =

  init: (element, valueAccessor) ->
    observable = valueAccessor()
    f = false
    _setClass = (val) ->
      if !val
        $(element).addClass "error"
      else
        $(element).removeClass "error"

    observable.isModified.subscribe ->
      f = true
      _setClass observable.isValid()

    observable.isValid.subscribe (val) ->
      #skip first apperance
      if f then _setClass val

    ko.utils.domNodeDisposal.addDisposeCallback element, ->
      console.log "dispose"
      $(element).removeClass "error"

ko.bindingHandlers.validation =

  init: (element, valueAccessor, allBindingsAccessor) ->
    all = allBindingsAccessor()
    prop =
      if all.value
        all.value
      else if all.autocomplete
        all.autocomplete
      else if all.datetime
        all.datetime
    if prop
      validation = valueAccessor()
      validation = [validation] if !Array.isArray validation
      for v in validation
        prop.extend v

###
ko.bindingHandlers.customError =

  init: (element, valueAccessor, allBindingsAccessor, viewModel) ->
    if viewModel.customErrors
      observable = valueAccessor()
      prop = observable()
      viewModel.customErrors.subscribe (val) ->
        if !$(element).text()
          err = viewModel.customErrors().filter((f) -> f.field == prop)[0]
          if err
            $(element).text err
###

ko.bindingHandlers.link =
  init: (element, valueAccessor, allBindingsAccessor) ->
    opts = allBindingsAccessor().linkOpts
    $(element).click (event) ->
      event.preventDefault()
      value = ko.utils.unwrapObservable(valueAccessor())
      if value
        window.location = "/#{opts.resource}/#{value}"
      false
