MM.ui 'map', (opts) ->
  
  class Map
    
    constructor: (@el) ->
      @top = 0
      @left = 0
      @change = 2
      
    panStart: (direction) ->
      if direction == 'left'
        $.loop.add 'pan_map_left', =>
          @el.css
            left: MM.map.left += MM.map.change
      if direction == 'right'
        $.loop.add 'pan_map_right', =>
          @el.css
            left: MM.map.left -= MM.map.change
      if direction == 'up'
        $.loop.add 'pan_map_up', =>
          @el.css
            top: MM.map.top += MM.map.change
      if direction == 'down'
        $.loop.add 'pan_map_down', =>
          @el.css
            top: MM.map.top -= MM.map.change

    panStop: (direction) ->
      $.loop.remove 'pan_map_' + direction
      
  ui_path = 'maps/map_' + opts.map_id
  MM.require ui_path, 'css'
  
  MM.run ->
    MM.render opts.el, ui_path
    
    # json data to initialize map
    MM.map = new Map opts.el