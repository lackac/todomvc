{get, view, ready} = require('derby').createApp module

## ROUTES ##

get '/', (page) ->
  page.redirect '/derby'

get '/:groupName', (page, model, {groupName}) ->
  groupTodosQuery = model.query('todos').where('group').equals(groupName)
  model.subscribe "groups.#{groupName}", groupTodosQuery, (err, group) ->
    model.ref '_group', group
    todoIds = group.at 'todoIds'
    group.setNull 'id', groupName

    # The refList supports array methods, but it stores the todo values
    # on an object by id. The todos are stored on the object 'todos',
    # and their order is stored in an array of ids at '_group.todoIds'
    model.refList '_todoList', 'todos', todoIds

    # Add some default todos if this is a new group. Items inserted into
    # a refList will automatically get an 'id' property if not specified
    unless todoIds.get()
      model.push '_todoList',
        {group: groupName, text: 'Example todo'},
        {group: groupName, text: 'Another example'},
        {group: groupName, text: 'This one is done already', completed: true}

    # Create a reactive function that automatically keeps '_remaining'
    # updated with the number of remaining todos
    model.fn '_remaining', '_todoList', (list) ->
      remaining = 0
      for todo in list
        remaining++ unless todo?.completed
      return remaining

    page.render()


## CONTROLLER FUNCTIONS ##

ENTER_KEY = 13

ready (model) ->

  list = model.at '_todoList'

  newTodo = model.at '_newTodo'
  exports.add = (event) ->
    if event.type == 'keyup' && event.which == ENTER_KEY
      # Don't add a blank todo
      return unless text = view.escapeHtml newTodo.get().trim()
      newTodo.set ''
      list.push {text}

  exports.del = (e) ->
    # Derby extends model.at to support creation from DOM nodes
    model.at(e.target).remove()


  showReconnect = model.at '_showReconnect'
  showReconnect.set true
  exports.connect = ->
    showReconnect.set false
    setTimeout (-> showReconnect.set true), 1000
    model.socket.socket.connect()

  exports.reload = -> window.location.reload()
