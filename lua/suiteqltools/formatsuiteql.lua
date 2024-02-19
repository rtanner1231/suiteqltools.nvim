
local Common=require('suiteqltools.util.common')
local Config=require('suiteqltools.config')
local TreesitterLookup=require('suiteqltools.util.treesitter_lookup')

local M={}

local doSqlFormat=function(sqlString,sqlArgs)

    local fullPath= debug.getinfo(1).source:sub(2)


    local scriptPath=Common.getScriptPath(fullPath,'/lua/suiteqltools','scripts/sqlformatter/formatsql.js')

    local argsStr=' --query '..'"'..sqlString..'"'

    for k,v in pairs(sqlArgs) do
        local key=string.lower(k)
        argsStr=argsStr..' --'..key.. ' '..tostring(v)
    end


    local command='node '..scriptPath..argsStr

    --print(command)

    local result=vim.fn.systemlist(command)

    return result

    
end



local getStringInterpolationMatchArray=function(str)
    -- local matches=string.gmatch(str,'(${.-})')
    -- local i=1
    -- local matchArr={}
    -- local matchSet={}
    -- for m in matches do
    --     if matchSet[m]==nil then
    --         local sub='xxrep4567xx'..i
    --         table.insert(matchArr,{sub=sub,val=m})
    --         i=i+1
    --         matchSet[m]=true
    --     end
    -- end

    local strIntVals=Common.getStringInterpolation(str)
    local matchArr={}

    local i=1

    for _,v in ipairs(strIntVals) do
        local sub='xxrep4567xx'..i
        table.insert(matchArr,{sub=sub,val=v})
        i=i+1
    end

    

    return matchArr

end

local substituteMatches=function(str,matchArr)
    for _,v in pairs(matchArr) do
        str=Common.replace(str,v.val,v.sub)
    end
    return str
end

local restoreMatches=function(strTbl,matchArr)
    local ret={}
    for _,tblVal in ipairs(strTbl) do
        for _,v in pairs(matchArr) do
            tblVal=Common.replace(tblVal,v.sub,v.val)
        end
        
        table.insert(ret,tblVal)
    end
    return ret
end


local run_format=function(pos,bufnr)
    pos=pos or nil
    bufnr=bufnr or vim.api.nvim_get_current_buf()

    local filetype=vim.bo.filetype

    if(filetype~='typescript' and filetype~='javascript') then
        return
    end


    local changes={}

    local nodes={}

    if pos==nil then
        nodes=TreesitterLookup.getFileQueries()
    else
        nodes=TreesitterLookup.getCurrentQuery()
    end

    if #nodes==0 then
        return
    end

    for _,node in ipairs(nodes) do
        local range={node:range()}
        local indent=string.rep(" ",range[2])
        local sql_text=vim.treesitter.get_node_text(node,bufnr)

        --remove template quotes from start and end
        --these break the formatter if left in
        local trimmed_text=string.sub(sql_text,2,string.len(sql_text)-1)
        --$ characters break the formatter, remove them
        --trimmed_text=remove_dollar(trimmed_text)
        local dollarMatches=getStringInterpolationMatchArray(trimmed_text)
        trimmed_text=substituteMatches(trimmed_text,dollarMatches)


        local formatted_lines=doSqlFormat(trimmed_text,Config.options.sqlFormatter)
        --print(vim.inspect(formatted_lines))
        --resurround with template quotes
        --formatted_text='`\n'..formatted_text..'\n`'
        table.insert(formatted_lines,1,'`')
        table.insert(formatted_lines,'`')

        --readd $ characters
        --formatted_text=restore_dollar(formatted_text)
        formatted_lines=restoreMatches(formatted_lines,dollarMatches)



        --convert from string to table of lines
        --local formatted_lines=lines(formatted_text)

        for idx,line in ipairs(formatted_lines) do
            if idx>1 then
                formatted_lines[idx]=indent..line
            end
        end

        table.insert(changes,1,{start_row=range[1],start_col=range[2], end_row=range[3],end_col=range[4],formatted=formatted_lines})
    end

    for _, change in ipairs(changes) do
        vim.api.nvim_buf_set_text(bufnr,change.start_row,change.start_col,change.end_row,change.end_col,change.formatted)
    end
end

M.formatQuery=function(q)
    return doSqlFormat(q,Config.options.sqlFormatter)
end

M.runFormatCurrent=function()
    local pos=vim.api.nvim_win_get_cursor(0)
    run_format(pos)
end

M.runFormatAll=function()
    run_format()
end




-- vim.api.nvim_create_user_command("TestFormatSuiteQL",function()
--     run_format()
-- end,{})
--
-- vim.api.nvim_create_user_command("TestFormatSingleSuiteQL",function()
--     local pos=vim.api.nvim_win_get_cursor(0)
--     run_format(pos)
-- end,{})
--
-- local P=function(tbl)
--     return print(vim.inspect(tbl))
-- end
--
-- local q="select child.id as item, coalesce(parentipc.id, childipc.id) as id, coalesce( parentipc.custrecord_jetline_itemconfig_impmeth, childipc.custrecord_jetline_itemconfig_impmeth) as imprint, coalesce( parentipc.custrecord_imprint_location_name, childipc.custrecord_imprint_location_name) as location from item child left outer join CUSTOMRECORD_JETLINE_ITEMCONFIG childipc on childipc.custrecord_jetline_itemconfig_item = child.id left outer join item parent on parent.id = child.parent left outer join CUSTOMRECORD_JETLINE_ITEMCONFIG parentipc on parentipc.custrecord_jetline_itemconfig_item = parent.id where child.id in (<><{items.join(',')}) and nvl(childipc.isInactive, 'F') = 'F' and nvl(parentipc.isinactive, 'F') = 'F'"
--
-- local test=function()
--     --local res=doSqlFormat("select * from location where name='<><{name}'",{language='sql',keywordCase='upper'})
--     --local res=doSqlFormat("select * from location where name='<><{name}'",Config.options.sqlFormatter)
--     local res=doSqlFormat(q,Config.options.sqlFormatter)
--     --P(res)
-- end
--
-- --test()
--
-- local test_regex_find=function()
--     local q="select * from location l where l.name=${name} or l.id=${id.join(',')} and l.isinactive='F' and l.secondname=${name}"
--     local m=getStringInterpolationMatchArray(q)
--     local newq=substituteMatches(q,m)
--
--     print(newq)
--
--     local reqq=restoreMatches(newq,m)
--
--     print(reqq)
--
--     --print(replace(q,"${id.join(',')}",'reaaa'))
--
-- end
--
-- test_regex_find()


return M
