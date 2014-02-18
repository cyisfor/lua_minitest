package="minitest"
version="0.1-1"
source = {
   url = "git://github.com/cyisfor/lua_minitest.git",
   dir='lua_minitest'
}
description = {
   summary = "A compact nice testing framework",
   detailed = [[
       I didn't like how complicated and buggy busted was, so I made this. 
       Should do approximately the same thing for most cases, and the correct thing in other cases.
   ]],
   homepage = "http://github.com/cyisfor/lua_minitest/",
   license = "lol"
}
dependencies = {
   "lua >= 5.1"
}

build = {
   -- type = "command", build_command="bash",
   type="builtin",
   modules = {
       minitest = "minitest.lua",
       betterError = "betterError.lua",
   }
}
