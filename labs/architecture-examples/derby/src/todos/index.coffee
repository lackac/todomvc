{get, view, ready} = require('derby').createApp module

## ROUTES ##

get '/', (page, model) ->

  # Order todos by created_at
  query = model.query('todos').sort('created_at', 'asc')

  model.subscribe query, (err, todos) ->
    model.set '_todoIds', (id for id of todos.get())

    # The refList supports array methods, but it stores the todo values
    # on an object by id. The todos are stored on the object 'todos',
    # and their order is stored in an array of ids at '_todoIds'
    model.refList '_todos', 'todos', '_todoIds'

    # Create a reactive function that automatically keeps '_remaining'
    # updated with the number of remaining todos
    model.fn '_remaining', '_todos', (list) ->
      remaining = 0
      remaining++ for {completed} in list when not completed
      return remaining

    page.render()


## CONTROLLER FUNCTIONS ##

ENTER_KEY = 13

ready (model) ->

  todos = model.at '_todos'

  newTodo = model.at '_newTodo'
  exports.add = (event) ->
    if event.type == 'keyup' && event.which == ENTER_KEY
      # Don't add a blank todo
      return unless text = newTodo.get().trim()
      newTodo.set ''
      todos.push {text, created_at: Date.now()}

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
