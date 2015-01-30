__ashita_libs = __ashita_libs or { };
__ashita_libs.powerargs = powerargs;

---------------------------------------------------------------------------------------------------
-- func: PowerArgs
-- desc: Provides relevant information about command arguements
---------------------------------------------------------------------------------------------------
function PowerArgs(eargs)
    -- store parameters
    params = { }
    for index = 2, #eargs do table.insert(params, eargs[index]) end

    -- contains argument info
    local arg_info =
    {
        parameters = params,
        -- arg  count
        count = #eargs,
        -- the command or nil
        command = (#eargs < 1) and nil or eargs[1],
        -- args contains a command
        has_command = #eargs >= 1,
        -- commands has paramter(s)
        has_parameters = #eargs >= 2,
        -- number of parameters
        parameter_count = #eargs - 1
    }

    return arg_info
end
