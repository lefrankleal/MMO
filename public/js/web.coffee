WEB = {}

WEB.VERSION = window.VERSION || guid()

WEB.options =
  paths:
    tpl: '/tpl/'
    css: '/css/'
    js: '/js/'
    modules: '/js/modules/'

WEB.namespace = (namespace) ->
  window[ namespace ] = WEB

# WEB.log
WEB.log = (label, print = null) ->
  if console?
    if print? 
      console.log label + ' => ' + print
      return
    console.log label

# WEB.use
# EXAMPLES:
# 	WEB.use 'feed'		--->	lazyloads /js/ui/feed.js
#										--->	then runs WEB.add 'feed', (opts)->
#										--->	then runs WEB.use 'feed', options
module = new Object
WEB.add = (name, fn) ->
  if !module.hasOwnProperty( name )
    module[name] = fn
WEB.use = (name, opts) ->
  if module.hasOwnProperty( name )
    return module[name] opts
  WEB.require name
  WEB.run ->
    if module.hasOwnProperty( name )
      module[name] opts

extensions = []
WEB.extend = (name, ext) ->
  if !WEB[name]?
    WEB[name] = ext
    extensions.push name

# ajax calls
ajax = (options) ->
  return $.ajax options
WEB.get = (options) ->
  options.type = 'GET'
  ajax options
WEB.post = (options) ->
  options.type = 'POST'
  ajax options
WEB.put = (options) ->
  options.type = 'PUT'
  ajax options
WEB.del = (options) ->
  options.type = 'DELETE'
  ajax options

# history bindings
History = window.History
History.Adapter.bind window, 'statechange', ->
  data = History.getState().data
  if data? and data.module?
	  WEB.use data.module, data
WEB.go = (opts) ->
  if opts.path == window.location.pathname or document.location.href.match("#.[a-zA-Z0-9/]+\\?")
    WEB.use opts.module, opts
  History.pushState opts, opts.title, opts.path

# WEB.require
# EXAMPLES:
# 	WEB.require 'date' 					---> /js/ui/date.js
js_queue = []
css_queue = []
paths_list = {}
WEB.require = (name, type='js') ->

  # have we required this path before?
  key = name + '.' + type
  if paths_list[key]?
    return
  paths_list[key] = true

  if type == 'js'
    src = WEB.options.paths.modules + name + '.js?v=' + WEB.VERSION
    js_queue.push src
  else
    src = WEB.options.paths.css + name + '.css?v=' + WEB.VERSION
    css_queue.push src

WEB.run = (fn) ->
  if css_queue.length > 0
    LazyLoad.css css_queue
    css_queue = []
  if js_queue.length > 0
    LazyLoad.js js_queue, ->
      fn()
    js_queue = []
  else
    fn()

# WEB.render - templating with jade
# WEB.render '#myDiv', 'feed/football', options, callback
jade = require 'jade'
WEB.render = (el, filename, options={}, callback) ->
  tpl_path = WEB.options.paths.tpl + filename + '.jade?v=' + WEB.VERSION
  req = WEB.get
    url: tpl_path
    async: false
    dataType: 'text'
  req.success (res) ->
    el.html jade.render res, options
    if callback
      callback()

# WEB.route - client-side pathname-based routing
# call WEB.route() to route to the current pathname
# call WEB.route('/pathname') to route to /pathname
# the routes data structure (array of objects)
# [
#   {
#     path: regexObj
#     fn: function
#   },
#   {
#     path: regexObj
#     fn: function
#   },
# ]
routes = []

WEB.route = (pathname=null) ->
  # route action WEB.route
  if pathname == null
    try
      WEB.route document.location.href.match("#.[a-zA-Z0-9/]+\\?")[0].replace( new RegExp('[#.\\?]', 'g'), '' )
    catch error
      WEB.route document.location.pathname
    return
  for route in routes
    if pathname.match getPatternRegex route.path
      route.fn tokenize route.path, pathname
      break

WEB.addRoute = (path, fn=[]) ->
  # create regular expression of the path
  # add stuff to identify this route
  lastChar = path.substring path.length - 1, path.length
  if lastChar is '/'
    routes.push
      path: path.slice(0, -1)
      fn: fn
    routes.push
      path: path
      fn: fn
  else
    routes.push
      path: path + '/'
      fn: fn
    routes.push
      path: path
      fn: fn

getPatternRegex = (pattern) ->
  alnum_pattern = '[-_a-zA-Z0-9]+'
  token_re = new RegExp ':' + alnum_pattern, 'g'
  pattern_re = pattern.replace token_re, alnum_pattern
  new RegExp '^' + pattern_re + '$'

tokenize = (pattern, url) ->
  params = {}
  h_frags = pattern.split '/'
  u_frags = url.split '/'
  for h_frag in h_frags
    if h_frag.substr(0, 1) == ':'
      h_frag = h_frag.substr 1
      params[h_frag] = u_frags[_i]
  params

WEB.comet = $.noop

# WEB.comet
$ ->
  comet = {}
  socket = io.connect('http://' + document.domain);
  WEB.comet = (channel, fn) ->
    socket.on channel, (data)->
      fn data

WEB.resetUI = ->
  $('*').unbind().undelegate().die()

@WEB = WEB