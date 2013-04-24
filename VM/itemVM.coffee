define ["Ural/Modules/pubSub"], (pubSub) ->

  class ViewModel

    constructor: (@resource, @parentItem) ->
      @useGetNewRemote = true

    completeUpdate: (data, skipStratEdit) ->
      if @src
        #item was in edit mode
        @src.item.map data, skipStratEdit
      else
        #direct update
        @map data, skipStratEdit

    completeCreate: (data) ->
      @setSrc null, null
      @map data, keepEdit

    map: (data, skipStratEdit) ->

      data = data[0] if $.isArray()
      dataIndexVM = {}

      #exclude index view models from mapping
      for own prop of @
        #TO DO: change property check to instanceof ItemVM (Circular Dependencies problem)
        if @[prop] and data[prop] and @[prop].list
          dataIndexVM[prop] = data[prop]
          delete data[prop]

      #convert fields to js dates
      for own prop of data
        d = @tryDate data[prop]
        data[prop] = d if d

      ko.mapping.fromJS data, {}, @

      #map index view models now
      for own prop of dataIndexVM
        @[prop].map dataIndexVM[prop]

      @errors = ko.validation.group @

      if !skipStratEdit
        @startEdit()

    tryDate: (str) ->
      if str and typeof str == "string"
        match = /\/Date\((\d+)\)\//.exec str
        if match
          moment(str).toDate()

    clone: (status) ->
      vm = @onCreate()
      vm.map @toData()
      vm.setSrc @, status
      vm

    onCreate: ->
      new ViewModel @resource, @parentItem

    setSrc: (item, status) ->
      @src =
        item : item
        status : status

    cancel: (item, event) ->
      event.preventDefault()
      pubSub.pub "crud", "cancel", resource : @resource, status : @src.status

    confirmEvent: (event, eventName) ->
      attr = $(event.target).attr "data-bind-event"
      !attr or attr == eventName

    startUpdate: (item, event) ->
      if @confirmEvent event, "startUpdate"
        event.preventDefault()
        pubSub.pub "crud", "start_update", @clone "update"

    startRemove: (item, event) ->
      if @confirmEvent event, "startRemove"
        event.preventDefault()
        pubSub.pub "crud", "start_delete", @clone "delete"

    create: (item, event) ->
      if @confirmEvent event, "create"
        event.preventDefault()
        pubSub.pub "crud", "create", @

    update: (item, event) ->
      if @confirmEvent event, "update"
        event.preventDefault()
        pubSub.pub "crud", "update", @

    remove: (item, event) ->
      if @confirmEvent event, "remove"
        event.preventDefault()
        pubSub.pub "crud", "delete", @

    details: (item, event) ->
      if @confirmEvent event, "details"
        event.preventDefault()
        pubSub.pub "crud", "details", item : @clone "details"

    startEdit: ->
      @stored_data = @toData()

    cancelEdit: (item, event) ->
      event.preventDefault()
      if @stored_data
        @map @stored_data

    setErrors: (errs) ->
      for err in errs
        flag = false
        #check if not exists
        rule = @[err.field].rules().filter((f) -> f.params == "custom")[0]
        if rule then @[err.field].rules.remove rule
        @[err.field].extend
          validation:
            params: "custom"
            validator: (val, otherVal) ->
              _flag = flag
              flag = true
              _flag
            message:
              err.message

    toData: ->
      data = ko.mapping.toJS @
      #map children list properties
      for own prop of @
        #TO DO: change property check to instanceof ItemVM (Circular Dependencies problem)
        #if property name starts with _, this is private property, don't map (recursive index <-> item problem)
        if prop.indexOf("_") != 0 and @[prop] and @[prop].list
          data[prop] = @[prop].list().map (m) -> m.toData()
      data
