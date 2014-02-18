local ansicolors = require('ansicolors')
local betterError = require('betterError')

local startingTest = ansicolors('%{blue}○')
local success = ansicolors('%{green}●')
local pending = ansicolors('%{yellow}●')
local failure = ansicolors('%{red}●')

local backspace = string.char(8)

local function makeContext(root)
    function recontext(parent,name)
        return {
            root=root,
            parent=parent,
            name=name,
            describe = function (self,name,describer)
                status, err = pcall(describer,recontext(self,name))
                if not status then error(err) end
            end,
            it = function (self,name,test)
                io.write(startingTest)
                setfenv(test,_G)
                status, err = pcall(test)
                io.write(backspace)
                maybefuture = err
                t = type(maybefuture)
                if status and (t=='function' or (t=="table" and maybefuture.__call)) then
                    io.write(pending)
                    oldcontext = context
                    status, err = pcall(maybefuture)
                    context = oldcontext
                end
                if status then
                    io.write(success)
                    root.successes = root.successes + 1
                else
                    io.write(failure)
                    root.failures = root.failures + 1
                    root.errors[#root.errors+1] = {err=err,name=name,context=self}
                end
            end
        }
    end
    return recontext()
end

local function betterError(andThen,...) 
    olderror = error
    local function newerror (message)
        return olderror({message=message,info=debug.getinfo(3),traceback=debug.traceback()})
    end  
    _G.error = newerror
    env = getfenv(andThen)
    env.error = newerror
    setfenv(andThen,env)
    result = {pcall(andThen, ...)}
    error = olderror
    status,err = unpack(result)
    if status == false then
        while(type(err) ~= "string") do
            print(err.traceback)
            print(err.info.source..":"..err.info.currentline)
            print('---')
            err = err.message
        end
        error(err)
    end
    table.remove(result,1)
    return unpack(result)
end

local function withTests(makeTests)
    context = makeContext({
            successes = 0,
            failures = 0,
            errors = {}
        })

    setfenv(makeTests,getfenv())
        
    local status,bigerr = pcall(makeTests,context)

    io.write('\n')

    for i,err in ipairs(context.root.errors) do
        io.write('Test ')
        local ctx = err.context
        local first = true
        while ctx and ctx.name do
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
        io.write(err.name..' failed!\n')
        err = err.err
        if(type(err)=="string") then
            print('this should not be a string! but ',err)
        else
            print(err.message)
            print(err.info.source..":"..err.info.currentline)
            --print(err.err.traceback)
        end
    end
    if not status then error(bigerr) end
    
    -- I am so finicky
    local succname
    local failname
    if context.root.successes ~= 1 then
        succname = 'successes'
    else
        succname = 'success'
    end
    if context.root.failures ~= 1 then
        failname = 'failures'
    else
        failname = 'failure'
    end

    print(ansicolors(string.format('%%{green}%d '..succname..' %%{red}%d '..failname,
        context.root.successes,
        context.root.failures)))

end

return function(makeTests) betterError(withTests,makeTests) end
