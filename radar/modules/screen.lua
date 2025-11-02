
-- K4RLOW

local self = {}

self.size = {guiGetScreenSize()}
self.base = {x = 1920, y = 1080}
self.scal = math.min(math.max((self.size[2] / self.base.y), 0.85), 2)  

return self