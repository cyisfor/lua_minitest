return function (andThen,...) 
    local olderror = error
    local function newerror (message)
        -- print('got',debug.traceback())
        return olderror({message=message,info=debug.getinfo(3),traceback=debug.traceback()})
    end  
    _G.error = newerror
    env = getfenv(andThen)
    env.error = newerror
    setfenv(andThen,env)
    -- print('a')
    result = {pcall(andThen, ...)}
    -- print('b')
    error = olderror
    local status,err = unpack(result)
    if status == false then
        print('HI',err)
        while(type(err) ~= "string") do
            print(err.traceback)
            print(err.info.source..":"..err.info.currentline)
            print('---')
            err = err.message
        end
        error(err)
    end
    print('hi',status)
    table.remove(result,1)
    return unpack(result)
end
