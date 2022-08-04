local controlpanel = require("controlpanel")

local cp = controlpanel.new("top")

local led = cp.newLabeledLED({1,12},controlpanel.colors.green,"Blinken Lights")

local knob = cp.newKnob({10,1},controlpanel.colors.red,{"LOW","MED","HIGH"},function() end)

cp.newButton({1,1},controlpanel.colors.blue,"Nothing", function (self)
  self.set(not self.get())
end)

local disp = cp.newSmallDisplay({16,11},controlpanel.colors.yellow,6)

cp.addTimer(0.5, function()
  led.set(not led.get()) -- blink the LED every second
end)

cp.addTimer(0.25, function()
  disp.set(math.random(100000*knob.get()))
end)

cp.start()