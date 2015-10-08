local events = require 'events'

local emitterX = {}

emitterX = events:EventEmitter(emitterX)

emitterX:on('h', function (...) 
    print('hello')
    print(...)
end)

emitterX:once('hx', function (...) 
    print('helloxxxxxx')
    print(...)
end)

emitterX:emit('h', { x = 3 }, 'yyoyoyo111')

emitterX:emit('h', { x = 3 }, 'yyoyoyo2222')
emitterX:emit('hx', { x = 1 }, 'yyoyoyo')
emitterX:emit('hx', { x = 2 }, 'yyoyoyo')
emitterX:emit('hx', { x = 3 }, 'yyoyoyo')