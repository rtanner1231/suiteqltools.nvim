local Completion = require("suiteqltools.completion.completionData")
local TableLookup = require("suiteqltools.tableopen.tablelookup")
local NSConn = require('nsconn')
local Common = require('suiteqltools.util.common')

local M = {}

local get_table_type = function(str)
    if type(str) ~= 'string' then
        return nil
    end

    if vim.startswith(str, 'customlist') then
        return 'list'
    end

    if vim.startswith(str, 'customrecord') then
        return 'record'
    end

    return nil
end

local get_base_url = function()
    local account = NSConn.getURLAccount()
    if not account then
        return nil
    end
    return string.format('https://%s.app.netsuite.com/app/', account)
end

local get_url_parms_string = function(type, isEdit)
    if isEdit then
        if type == 'record' then
            return 'common/custom/custrecord.nl?id=%s&e=T'
        elseif type == 'list' then
            return 'common/custom/custlist.nl?id=%s&e=T&ord=T'
        end
    else
        return 'common/custom/custrecordentrylist.nl?rectype=%s'
    end

    return nil
end





local get_url_from_id = function(id, tableType, isEdit)
    local baseUrl = get_base_url()
    if baseUrl == nil then
        return nil
    end

    local parmsTemplate = get_url_parms_string(tableType, isEdit)

    if parmsTemplate == nil then
        return nil
    end

    local parmsString = string.format(parmsTemplate, id)

    return baseUrl .. parmsString
end


local openTable = function(id, isEdit)
    local tableType = get_table_type(id)
    if tableType == nil then
        return
    end

    local internalId = TableLookup.getInternalId(id)
    if internalId == nil then
        return
    end

    local tableUrl = get_url_from_id(internalId, tableType, isEdit)

    if tableUrl == nil then
        return
    end

    Common.openUrl(tableUrl)
end

M.editTable = function(id)
    openTable(id, true)
end

M.listTable = function(id)
    openTable(id, false)
end

M.editTableForWordUnderCursor = function()
    local word = Common.getWordUnderCursor()
    if word == nil then
        return
    end
    M.editTable(word)
end

M.listTableForWordUnderCursor = function()
    local word = Common.getWordUnderCursor()
    if word == nil then
        return
    end
    M.listTable(word)
end


return M
