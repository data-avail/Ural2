define ["Ural/Modules/pubSub", "Ural/Modules/dataProvider"], (pubSub, dataProvider) ->

  class Controller

    constructor: (@viewModel) ->

      ko.applyBindings viewModel, $("#body")[0]

      pubSub.sub "crud", "start_create", (item) => @crudStartCreate item
      pubSub.sub "crud", "start_update", (item) => @crudStartUpdate item
      pubSub.sub "crud", "start_delete", (item) => @crudStartDelete item
      pubSub.sub "crud", "get", (opts) => @crudGet opts
      pubSub.sub "crud", "create", (item) => @crudCreate item
      pubSub.sub "crud", "update", (item) => @crudUpdate item
      pubSub.sub "crud", "delete", (item) => @crudDelete item
      pubSub.sub "crud", "details", (item) => @crudDetails item
      pubSub.sub "crud", "cancel", (opts) => @crudCancel opts
      pubSub.sub "crud", "action", (opts) => @crudAction opts

    crudAction: (opts) ->
      dataProvider.action opts.resource, opts.name, opts.data, (err, data) =>
        @crudDone null, err, "Выполнено успешно"
        if !err and opts.success
          opts.success data

    crudDetails: (item) ->
      window.location = dataProvider.getUrl item.resource, "details", item.toData()

    crudGet: (opts)->
      dataProvider.get opts.resource, opts.filter, (err, data) =>
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
        dataProvider.getNew item.resource, (if item.parentItem then item.parentItem.toData() else null), (err, data) =>
          if err
            @crudDone err
          else
            item.map data
            item.errors.showAllMessages false
            @showForm item.resource, "create", item
      else
        @showForm item.resource, "create", item

    crudStartUpdate: (item) ->
      @showForm item.resource, "update", item

    crudCancel: (opts) ->
      @hideForm opts.resource, opts.status

    crudCreate: (item) ->
      if item.isValid()
        dataProvider.create item.resource, item.toData(true), (err, data) =>
          @crudDone item, err, "Создано успешно"
          if !err
            if !item.useRepeatCreate or !item.useRepeatCreate()
              @hideForm item.resource, "create"
              item.completeCreate data
            else
              item.map data
            pubSub.pub "crud", "complete_create", item.clone()
      else
        @crudDone item, message : "Неправильные данные"

    crudUpdate: (item) ->
      if item.isValid()
        dataProvider.update item.resource, item.toData(true), (err, data) =>
          @crudDone item, err, "Сохранение успешно"
          if !err
            @hideForm item.resource, "update"
            item.completeUpdate data
      else
        @crudDone item, message : "Неправильные данные"

    crudDelete: (item) ->
      dataProvider.delete item.resource, item.toData(true), (err) =>
        @crudDone item, err, "Удалено успешно"
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
      form.modal("show").on("hidden", -> ko.cleanNode form[0])

    hideForm: (resource, formType) ->
      form = $("[data-form-type='"+formType+"'][data-form-resource='"+resource+"']")
      form.modal "hide"

