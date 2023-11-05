local Commands=require('suiteqltools.commands')

-- local SuiteQLTools=require('suiteqltools')
--
-- vim.api.nvim_create_user_command("TestFormatSuiteQL",function()
--     SuiteQLTools.runFormatCurrent()
-- end,{})
--
-- vim.api.nvim_create_user_command("TestSingleSuiteQLAll",function()
--     SuiteQLTools.runFormatAll()

-- end,{})

vim.api.nvim_create_user_command("SuiteQL",function(opts)
   if #opts.fargs==0 then
    return
   end

    Commands.runCommand(opts.args)

end,{
        nargs='?',
        complete=function(_,_,_)
            local cList={}
            for _,v in pairs(Commands.command_list) do
                table.insert(cList,v.value)
            end
            return cList
        end

    })

