# Control Panels
Control panel library for making control panels on monitors

specifically designed for monitors and control panels. no text input.

## Example
```lua
local cp = controlpanel.new("top")

cp.addEventListener("reactor_is_about_to_explode_event", function(reactorTemp, willDestroyTheWorld)
  --- do stuff
end)

local tempDisplay = cp.newLabeledMeter(
  {1,1}, cp.colors.red,
  "REACTOR TEMP",{0, 1500, 3000},{0,3000}
)

cp.addTimer(5, function()
  tempDisplay.set(reactor.getTemp())
end)

cp.start()
```

## This library depends on pixelbox for Meters and Knobs
https://github.com/9551-Dev/apis/blob/main/pixelbox.lua

## Random notes that will be helpful when you use this
each object contains `draw`, many data containing objects have `get` and `set`.

each object should claim a click area.

each object needs to add itself to the objects table so it is drawn.

`set` will automatically redraw the item.

all functions passed into objects as the touch handler
should take `self` as a parameter

Definitions of terms used as parameter names:

* `pos`, 1D table of {x,y} position on monitor
* `color`, a reference to a specially formatted color table
  * {`dim`,`bright`,`frame`,`label`,`text`}
* `label`, String label to mark the object with
* `size`, 1D table of {width, height}
* `digits`, int number of digits to show on the display
* `width`, width to make a text field, defaults to length of `label`
* `func`, touch handler function, first and only parameter is `self`.
  * `func` in `addEventListener` will be passed all parameters except name from the event.
* `range`, 1D table of {min, max}
* `labels`, 1D table of any length containing string representable data.