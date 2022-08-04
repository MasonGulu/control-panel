local cp = {}


--- TODO redo the color system, it sucks
local palette = {
  [colors.orange]=0xfb2727, -- bright red
  [colors.red]=0x832a2a, -- dark red
  [colors.lime]=0x09db06, -- bright green
  [colors.green]=0x153f29, -- dark green
  [colors.cyan]=0x278cff, -- bright blue
  [colors.blue]=0x35649a, -- dark blue
  [colors.yellow]=0xeec825, -- bright yellow
  [colors.pink]=0x907b24, -- dark yellow

  [colors.purple]=0xd8d9d3, -- beige-y background

  [colors.lightGray]=0xe2e5f4, -- metallic color
  [colors.white]=0xf4f4f4,
  [colors.black]=0x2d2c2b,
} -- leave black, and white intact

cp.colors = {
  red = {
    dim=colors.red, -- dark color
    bright=colors.orange, -- lit color
    frame=colors.lightGray, -- frame color (area around button)
    label=colors.white, -- label color
    text=colors.black, -- text color
  },
  blue = {
    dim=colors.blue, -- dark color
    bright=colors.cyan, -- lit color
    frame=colors.lightGray, -- frame color (area around button)
    label=colors.white, -- label color
    text=colors.black, -- text color
  },
  green = {
    dim=colors.green, -- dark color
    bright=colors.lime, -- lit color
    frame=colors.lightGray, -- frame color (area around button)
    label=colors.white, -- label color
    text=colors.black, -- text color
  },
  yellow = {
    dim=colors.pink, -- dark color
    bright=colors.yellow, -- lit color
    frame=colors.lightGray, -- frame color (area around button)
    label=colors.white, -- label color
    text=colors.black, -- text color
  },
}

function cp.new(side)
  local self = {}

  local mon = peripheral.wrap(side)
  assert(mon and mon.setTextScale, "Not a valid monitor")

  local timers = {} -- integer indexed list of timers
  -- {delay, function(), id}

  local activeTimers = {} -- lookup table
  -- [timerID] -> [timersIndex]

  local touchLookup = {} -- map of X, Y values to touch handlers

  local objects = {} -- integer indexed table of objects
  -- used for draw calls

  local eventListeners = {
    monitor_touch = function(es, x, y) -- es = eventside
      if touchLookup[x] and touchLookup[x][y] then
        -- touch handler function exists
        touchLookup[x][y](x,y)
      end
    end,
    timer = function(id)
      if not activeTimers[id] then
        return -- this isn't a timer we're interested in
      end
      local currentTimer = activeTimers[id]
      timers[currentTimer][2]() -- call the timer handler
      local newID = os.startTimer(timers[currentTimer][1])
      activeTimers[id] = nil -- erase the previous timer
      activeTimers[newID] = currentTimer
      timers[currentTimer][3] = newID -- establish linked data
    end
  }

  function self.addEventListener(en, func)
    assert(not eventListeners[en], "Event already registered")
    eventListeners[en] = func
  end

  local function startTimers()
    for k,v in pairs(timers) do
      local id = os.startTimer(v[1])
      activeTimers[id] = k
      v[3] = id
    end
  end

  local function drawObjects()
    for _, v in ipairs(objects) do
      v.draw()
    end
  end

  local function addToTouchMap(x,y,width,height, func)
    for dx = 0, width-1 do
      touchLookup[x+dx] = touchLookup[x+dx] or {}
      for dy = 0, height-1 do
        assert(not touchLookup[x+dx][y+dy],
          string.format("Overlapping components at %u %u.", x+dx, y+dy))
        touchLookup[x+dx][y+dy] = func
      end
    end
  end

  function self.addTimer(time, func)
    timers[#timers+1] = {time, func}
  end

  function self.start()
    for k,v in pairs(palette) do
      mon.setPaletteColor(k,v)
    end
    mon.setTextScale(1)
    mon.setBackgroundColor(colors.purple) -- beige background
    mon.clear()
    startTimers()
    drawObjects()
    while true do
      -- main event loop
      local event = {os.pullEvent()}
      if eventListeners[event[1]] then
        eventListeners[event[1]](table.unpack(event,2))
      end
    end
  end

  -- takes a device, format table, fg, and bg colors
  -- format table should be entries of
  -- {x,y,char,invertBool}
  local function drawSpecial(dev,t,fg,bg)
    for k,v in pairs(t) do
      if v[4] then
        dev.setTextColor(bg)
        dev.setBackgroundColor(fg)
      else
        dev.setTextColor(fg)
        dev.setBackgroundColor(bg)
      end
      dev.setCursorPos(v[1],v[2])
      dev.write(v[3])
    end
  end

  function self.newButton(pos, color, label, func)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}

    local BUTTON_WIDTH = 8
    local BUTTON_HEIGHT = 5
    local LABEL_HEIGHT = 3

    local dev = window.create(mon, pos[1],pos[2], BUTTON_WIDTH, BUTTON_HEIGHT+LABEL_HEIGHT)

    local function monitorTouch(x,y)
      x = x - pos[1] + 1
      y = y - pos[2] - LABEL_HEIGHT + 1
      -- adapt it to on the button
      func(self)
    end

    local function draw(fillCol)
      dev.setVisible(false)
      dev.setBackgroundColor(colors.purple) -- beige background
      dev.clear()
      dev.setBackgroundColor(color.label)
      for dy = 0,2 do
        dev.setCursorPos(1,pos[2]+dy)
        dev.write(string.rep(" ", BUTTON_WIDTH))
      end
      dev.setTextColor(color.text)
      dev.setCursorPos(1,1)
      dev.write(string.sub(label,1,8))
      dev.setCursorPos(1,2)
      dev.write(string.sub(label,9,16))
      dev.setBackgroundColor(fillCol)
      for dy = 3,6 do
        dev.setCursorPos(1,pos[2]+dy)
        dev.write(string.rep(" ", BUTTON_WIDTH))
      end

      drawSpecial(dev,{
        {3,3,"\159",true},
        {4,3,"\143",true},
        {5,3,"\143",true},
        {6,3,"\144"},-- first row
        {1,4,"\159",true},
        {2,4,"\129",true},
        {7,4,"\130",true},
        {8,4,"\144"}, -- second row
        {1,5,"\129",true},
        {8,5,"\130",true}, -- third row
        {1,6," ",true},
        {8,6," ",true}, -- fourth row
      },color.frame,color.label) -- top part of border where label is
      drawSpecial(dev,{
        {1,7,"\148",true},
        {8,7,"\151"},
        {2,8,"\139"},
        {3,8,"\144",true},
        {4,8," ",true},
        {5,8," ",true},
        {6,8,"\159"},
        {7,8,"\135"},
      },color.frame,colors.purple) -- bottom part of border where label isn't

      drawSpecial(dev, {
        {3,4,"\131"},
        {6,4,"\131"},
        {2,5,"\129"}, {7,5,"\130"},
        {2,6,"\144"}, {7,6,"\159",true},
        {2,7,"\130",true}, {3,7,"\143",true},{6,7,"\143",true}, {7,7,"\129",true}
      },color.frame,fillCol) -- inside of button area to make it more circular
      dev.setVisible(true)
    end

    local bright = false

    function self.draw()
      if bright then
        draw(color.bright)
      else
        draw(color.dim)
      end
    end

    function self.set(boolean)
      bright = boolean
      self.draw()
    end

    function self.get()
      return bright
    end

    addToTouchMap(pos[1], pos[2]+LABEL_HEIGHT,
     BUTTON_WIDTH, BUTTON_HEIGHT, monitorTouch)
    --- add self to touchmap

    objects[#objects+1] = self -- add self to object list

    return self
  end

  function self.newLabel(pos, color, size, label)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}

    local dev = window.create(mon, pos[1], pos[2], size[1], size[2])

    function self.draw()
      dev.setVisible(false)
      dev.setBackgroundColor(color.label)
      dev.setTextColor(color.text)
      dev.clear()
      local str = label
      while str:len() > size[1] do
        dev.setCursorPos(1,size[2])
        dev.write(str)
        dev.scroll(1)
        str = str:sub(size[1])
      end
      dev.setCursorPos(1,size[2])
      dev.write(str)
      dev.setVisible(true)
    end

    addToTouchMap(pos[1], pos[2],
     size[1], size[2], function() end)
    --- add self to touchmap

    objects[#objects+1] = self -- add self to object list

    return self
  end

  function self.newSmallDisplay(pos,color,digits)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}

    local dev = window.create(mon, pos[1], pos[2], digits+2,3)

    local value = 0

    function self.draw()
      -- draw a case around this first
      dev.setVisible(false)
      dev.setBackgroundColor(colors.black)
      dev.clear()
      drawSpecial(dev, {
        {1,1,"\159",true},
        {1,2,"\149",true},
        {1,3,"\130"},
        {digits+2,1,"\144"},
        {digits+2,2,"\149"},
        {digits+2,3,"\129"},
      },color.frame,colors.purple)
      for i = 2, digits+1 do
        drawSpecial(dev, {
          {i,1,"\143",true},
          {i,3,"\131"}
        },color.frame,colors.purple)
      end
      dev.setCursorPos(2,2)
      local str = tostring(value)
      if str:len() > digits then
        str = "OVERFLOW"
      end
      dev.setTextColor(color.dim)
      dev.setBackgroundColor(colors.black)
      for i = 1, digits - str:len()  do
        dev.write("_")
      end
      dev.setTextColor(color.bright)
      dev.write(str:sub(1,digits))
      dev.setVisible(true)
    end

    function self.set(val)
      value = val
      self.draw()
    end

    function self.get()
      return value
    end

    objects[#objects+1] = self

    return self
  end

  function self.newLabeledSmallDisplay(pos, color, digits, label, width)
    width = width or label:len()
    self.newLabel(pos, color, {width,1}, label)
    return self.newSmallDisplay({pos[1]+width,pos[2]-1},color, digits)
  end

  function self.newLED(pos,color)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}
    local value = false
    local dev = window.create(mon, pos[1], pos[2], 1, 1)
    function self.draw()
      dev.setVisible(false)
      dev.setBackgroundColor(colors.purple)
      if value then
        dev.setTextColor(color.bright)
      else
        dev.setTextColor(color.dim)
      end
      dev.setCursorPos(1,1)
      dev.write("\7")
      dev.setVisible(true)
    end

    function self.set(val)
      value = val
      self.draw()
    end

    function self.get()
      return value
    end

    objects[#objects+1] = self

    return self
  end

  -- width is optional
  function self.newLabeledLED(pos, color, label, width)
    width = width or label:len()
    self.newLabel(pos, color, {width,1}, label)
    return self.newLED({pos[1]+width,pos[2]},color)
  end

  -- labels will be a table of strings to display at regular intervals
  function self.newMeter(pos, color, labels, range)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}
    local WIDTH, HEIGHT = 16, 12
    local dev = window.create(mon, pos[1], pos[2], WIDTH, HEIGHT)

    local value = range[1] -- set to minimum of the range

    local function getCoordsMult(percentage,maxX, maxY)
      -- return x,y coord multipliers (multiply by the size)
      local x = 1-math.cos(percentage*(math.pi/2))
      local y = 1-math.sin(percentage*(math.pi/2))
      x = math.floor(x*maxX)
      y = math.floor(y*maxY)
      return x,y
    end


    function self.draw()
      dev.setVisible(false)
      local pixelbox = require("pixelbox")
      local px = pixelbox.new(dev, color.label)
      local px_top = 2
      local px_bottom = HEIGHT-1
      local px_left = 2
      local px_right = WIDTH-1
      px:set_circle(px_right*2,px_bottom*3,(WIDTH-2)*2*2-1,color.text,false,1)
      local x, y = getCoordsMult((value-range[1])/(range[2]-range[1]),
        (WIDTH-2)*2,(HEIGHT-2)*3)
      px:set_line(px_right*2,px_bottom*3, x+2,y+3,color.text,1)
      px:push_updates()
      px:draw()
      px = nil -- toss it out
      -- draw the frame
      drawSpecial(dev, {
        {1,1,"\159", true},
        {WIDTH,1,"\144"},
        {1,HEIGHT,"\130"},
        {WIDTH,HEIGHT,"\129"}
      }, color.frame, colors.purple)

      ---@diagnostic disable-next-line: redefined-local
      for x = 2, WIDTH-1 do
        drawSpecial(dev, {
          {x,1,"\143",true},
          {x,HEIGHT,"\131"}
        }, color.frame, colors.purple)
      end

      ---@diagnostic disable-next-line: redefined-local
      for y = 2, HEIGHT-1 do
        drawSpecial(dev, {
          {1,y,"\149",true},
          {WIDTH,y,"\149"}
        }, color.frame, colors.purple)
      end

      dev.setBackgroundColor(color.label)
      dev.setTextColor(color.text)
      local nlabels = #labels
      for k,v in ipairs(labels) do
        ---@diagnostic disable-next-line: redefined-local
        local x,y = getCoordsMult((k-1)/(nlabels-1),WIDTH-1,HEIGHT)
        if (x + tostring(v):len() > WIDTH-2) then
          -- this text will go off the right side
          x = WIDTH-2 - tostring(v):len() + 1-- make it fit
        end
        x = math.max(1, math.min(WIDTH-2, x))
        y = math.max(1, math.min(HEIGHT-2, y)) -- clamping
        dev.setCursorPos(x+1,y+1)
        dev.write(v)
      end

      dev.setVisible(true)

    end

    function self.set(val)
      value = math.min(math.max(val, range[1]), range[2])
      self.draw()
    end

    function self.get()
      return value
    end
    
    objects[#objects+1] = self

    return self
  end

  function self.newLabeledMeter(pos, color, label, labels, range)
    self.newLabel(pos, color, {16,1}, label) -- The size of this is hardcoded
    -- It should match the WIDTH in self.newMeter
    return self.newMeter({pos[1], pos[2]+1}, color, labels, range)
  end

  function self.newKnob(pos, color, labels, func)
    ---@diagnostic disable-next-line: redefined-local
    local self = {}

    local WIDTH, HEIGHT = 14,10
    local dev = window.create(mon, pos[1], pos[2], WIDTH, HEIGHT)

    local value = 1

    local function getCoords(percentage)
      -- return x,y coord multipliers (multiply by the size)
      -- semi circle
      -- x should range from 0-2 (left->right)
      -- y should range from 0-2 (top->bottom)
      local angle = math.max(math.min((percentage*math.pi*2) - (math.pi/2),
        math.pi*11/8), -math.pi/3) -- offset by 90 degrees ccw
      local x = math.cos(angle)
      local y = math.sin(angle)
      return x,y
    end

    function self.draw()
      -- setup 
      dev.setVisible(false)
      dev.setBackgroundColor(color.label)
      dev.clear()
      local pixelbox = require("pixelbox")
      local px = pixelbox.new(dev, colors.label)
      px:set_circle(WIDTH,math.floor(HEIGHT*3/2),WIDTH,color.frame,true)
      local x,y = getCoords((value-1)/(#labels-1))
      x = math.floor(x*WIDTH/2 + WIDTH)
      y = math.floor(y*WIDTH/2 + WIDTH)
      px:set_line(WIDTH,math.floor(HEIGHT*3/2),
        x,y,color.text)
      px:push_updates()
      px:draw()
      px = nil -- throw it away

      dev.setTextColor(color.text)
      dev.setBackgroundColor(color.label)
      -- now draw labels
      local nlabels = #labels
      for k,v in ipairs(labels) do
        ---@diagnostic disable-next-line: redefined-local
        local x,y = getCoords((k-1)/(nlabels-1))
        x = math.ceil(x*WIDTH/2 + WIDTH/2)
        y = math.ceil(y*HEIGHT/2 + HEIGHT/2)
        if (x + tostring(v):len() > WIDTH) then
          -- this text will go off the right side
          x = WIDTH - tostring(v):len() + 1-- make it fit
        end
        x = math.max(1, math.min(WIDTH, x))
        y = math.max(1, math.min(HEIGHT, y)) -- clamping
        dev.setCursorPos(x,y)
        dev.write(v)
      end
      dev.setVisible(true)
    end

    function self.get()
      return value -- returns the index of the selected item
    end

    function self.set(val)
      value = math.max(math.min(val, #labels), 1)
      self.draw()
    end

    addToTouchMap(pos[1], pos[2], WIDTH, HEIGHT, function(x,y)
      if x-pos[1] > WIDTH/2 then
        -- right side, increase
        self.set(self.get()+1)
      else
        -- left side, decrease
        self.set(self.get()-1)
      end
      self.draw()
      func(self)
    end)

    objects[#objects+1] = self

    return self
  end

  return self
end

return cp