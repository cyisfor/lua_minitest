local context
local root

local ansicolors = require('ansicolors')

local startingTest = ansicolors('%{blue}○')
local success = ansicolors('%{green}●')
local pending = ansicolors('%{yellow}●')
local failure = ansicolors('%{red}●')

local backspace = string.char(8)

local errors
local successes
local failures

local function minidescribe(name,describer)
    local save = context
    context = {
        name=name,
        parent = save
    }

    status, err = pcall(describer)
    context = save
    if not status then error(err) end
end

local function miniit(name,test)
    io.write(startingTest)
    status, err = pcall(test)
    io.write(backspace)
    maybefuture = err
    t = type(maybefuture)
    if status and (t=='function' or (t=="table" and maybefuture.__call)) then
        io.write(pending)
        status, err = pcall(maybefuture)
        io.write(backspace)
    end
    if status then            
        io.write(success)
        root.successes = root.successes + 1
    else
        io.write(failure)
        root.failures = root.failures + 1
        root.errors[#root.errors+1] = {err=err,name=name,context=context}
    end
end

local function withTests(makeTests)
    oldroot = root
    olddescribe = describe
    oldit = it
    root = {
        successes = 0,
        failures = 0,
        errors = {}
    }
    olderror = error

    _G.describe = minidescribe
    _G.it = miniit
    _G.error = function(message)
        assert(message)
        return olderror({message=message,info=debug.getinfo(3),traceback=debug.traceback()})
    end
    local status,bigerr = pcall(makeTests)

    _G.it = oldit
    _G.describe = olddescribe
    _G.error = olderror

    io.write('\n')

    for i,err in ipairs(root.errors) do
        io.write('Test ')
        local ctx = err.context
        local first = true    
        while(ctx) do
            if first then
                first = false
            else
                io.write('/')
            end
            io.write(ctx.name)
            ctx = ctx.parent
        end
        if first then
            first = false
        else
            io.write('/')
        end
        io.write(err.name..' failed!')
        print(err.err.message)
        print(err.err.info.source..":"..err.err.info.currentline)
        --print(err.err.traceback)
    end
    if not status then 
        local toperr = bigerr
        while toperr and type(toperr) ~= 'string' do
            print(toperr.traceback)
            toperr = toperr.message
        end
        if not toperr then
            error("nil argh")
        else
            error(toperr) 
        end
    end
    
    -- I am so finicky
    local succname
    local failname
    if root.successes ~= 1 then
        succname = 'successes'
    else
        succname = 'success'
    end
    if root.failures ~= 1 then
        failname = 'failures'
    else
        failname = 'failure'
    end

    print(ansicolors(string.format('%%{green}%d '..succname..' %%{red}%d '..failname,root.successes,root.failures)))

    root = oldroot
end

return withTests
