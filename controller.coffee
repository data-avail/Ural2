define ["Ural/Modules/pubSub", "Ural/Modules/dataProvider"], (pubSub, dataProvider) ->

  class Controller

    constructor: (@viewModel) ->

      @dataProvider = dataProvider.get()

      ko.applyBindings viewModel, $("#body")[0]

      pubSub.sub "crud", "start_create", (item) => @crudStartCreate item
      pubSub.sub "crud", "start_update", (opts) => @crudStartUpdate opts
      pubSub.sub "crud", "start_delete", (item) => @crudStartDelete item
      pubSub.sub "crud", "get", (opts) => @crudGet opts
      pubSub.sub "crud", "create", (item) => @crudCreate item
      pubSub.sub "crud", "update", (opts) => @crudUpdate opts
      pubSub.sub "crud", "delete", (item) => @crudDelete item
      pubSub.sub "crud", "details", (opts) => @crudDetails opts
      pubSub.sub "crud", "cancel", (opts) => @crudCancel opts
      pubSub.sub "crud", "start_action", (opts) => @crudStartAction opts
      pubSub.sub "crud", "action", (opts) => @crudAction opts

    getActionParams: (opts) ->
      #if opts.data isn't defined, consider viewModel as data source for this action data
      #opts.name - name of the action, only abrigatory parameter others: ([item], [resource])|(data, resource)
      name = opts.name
      if !opts.data
        item = if opts.item then opts.item else @viewModel
        resource = if opts.resource then opts.resource else item.resource
        data = item.toData()
      else
        resource = opts.resource
        data = opts.data

      name : name
      item : item
      resource : resource
      data : data

    getUpdateParams: (opts) ->
      if opts.item
        item : opts.item
        formType : opts.formType
      else
        item : opts
        formType : "update"

    crudStartAction: (opts) ->
      params = @getActionParams opts
      if !params.item then throw "opts should contain [item] field in order to execute crudStartAction"
      @showForm params.resource, params.name, params.item

    crudAction: (opts) ->
      params = @getActionParams opts
      if params.item
        if !params.item.isValid()
          @crudDone params.item, message : localization.controller.text.wrong_data
          return

      @dataProvider.action params.resource, params.name, params.data, (err, data) =>
        @crudDone null, err, localization.controller.text.success
        if !err
          if params.item
            @hideForm params.resource, params.name
          if opts.success
            opts.success data
          @onCrudActionSuccess params

    onCrudActionSuccess: (params) ->

    crudDetails: (opts) ->
      params = @getActionParams opts
      window.location = @dataProvider.getUrl params.resource, "details", params.data

    crudGet: (opts)->
      @dataProvider.get opts.resource, opts.filter, (err, data) =>
        vm = null
        if opts.resource == @viewModel.resource
          vm = @viewModel
        else
          for own prop of @viewModel
            if @viewModel[prop] and @viewModel[prop].list and @viewModel[prop].resource == opts.resource
              vm = @viewModel[prop]
              break
        if vm
          vm.map data

    crudStartDelete: (item) ->
      @showForm item.resource, "delete", item

    crudStartCreate: (item) ->
      if item.useGetNewRemote
        @dataProvider.getNew item.resource, (if item.parentItem then item.parentItem.toData() else null), (err, data) =>
          if err
            @crudDone err
          else
            item.map data
            item.errors.showAllMessages false
            @showForm item.resource, "create", item
      else
        @showForm item.resource, "create", item

    crudStartUpdate: (opts) ->
      params = @getUpdateParams opts
      @showForm params.item.resource, params.formType, params.item

    crudCancel: (opts) ->
      @hideForm opts.resource, opts.status

    crudCreate: (item) ->
      if item.isValid()
        @dataProvider.create item.resource, item.toData(true), (err, data) =>
          @crudDone item, err, localization.controller.text.created_success
          if !err
            if !item.useRepeatCreate or !item.useRepeatCreate()
              @hideForm item.resource, "create"
              item.completeCreate data
            else
              item.map data
            pubSub.pub "crud", "complete_create", item.clone()
      else
        @crudDone item, message : localization.controller.text.wrong_data

    crudUpdate: (opts) ->
      params = @getUpdateParams opts
      item = params.item
      formType = params.formType
      if item.isValid()
        @dataProvider.update item.resource, item.toData(), (err, data) =>
          @crudDone item, err, localization.controller.text.updated_success
          if !err
            @hideForm item.resource, formType
            item.completeUpdate data
      else
        @crudDone item, message : localization.controller.text.wrong_data

    crudDelete: (item) ->
      @dataProvider.delete item.resource, item.toData(true), (err) =>
        @crudDone item, err, localization.controller.text.deleted_success
        if !err
          @hideForm item.resource, "update"
          pubSub.pub "crud", "complete_delete", item

    crudDone: (item, err, succ) ->
      if err
        toastr.error err.message
        if item
          if err.errors
            item.setErrors err.errors
          item.errors.showAllMessages()
      else
        toastr.success succ

    showForm: (resource, formType, item) ->
      form = $("[data-form-type='"+formType+"'][data-form-resource='"+resource+"']")
      if !form[0] then throw "Required form not implemented"
      ko.applyBindings item, form[0]
      form.modal("show").on("hidden", ->
          #looks like cleanNode doesn't delete list-binded items, bug?
          item?.cleanUp()
          ko.cleanNode form[0])

    hideForm: (resource, formType) ->
      form = $("[data-form-type='"+formType+"'][data-form-resource='"+resource+"']")
      form.modal "hide"

