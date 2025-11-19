local M = {}

--Write text at position in positionParms after the cursor
--@param {bufnr: number,cursor: number[]} positionParms
M.writeToBufferPo = function(text, positionParms)
    local row = positionParms.cursor[1] - 1
    local col = 0
    local lines = vim.api.nvim_buf_get_lines(positionParms.bufnr, row, row + 1, false)

    --If the line length is 0, we must leave the column at 0.
    --Otherwise add 1 so the value is inserted after the cursor
    if #lines > 0 and #lines[1] > 0 then
        col = positionParms.cursor[2] + 1
    end
    vim.api.nvim_buf_set_text(positionParms.bufnr, row, col, row, col, { text })
    vim.api.nvim_win_set_cursor(positionParms.win, { row + 1, col + #text + 1 })
end

--Get the current buffer id and cursor position
--@returns {bufnr: number,cursor: number[]}
M.createPositionParms = function()
    local bufnr = vim.api.nvim_get_current_buf()
    local win = vim.api.nvim_get_current_win()
    local cursor = vim.api.nvim_win_get_cursor(0)
    return {
        bufnr = bufnr,
        cursor = cursor,
        win = win
    }
end

M.maxInList = function(list)
    local max = 0
    for _, v in ipairs(list) do
        if #v.id > max then
            max = #v.id
        end
    end

    if max > 50 then
        max = 50
    end

    return max
end

M.makeDisplay = function(max, entry)
    local id = entry.id

    if #id > max then
        id = id:sub(1, max - 3) .. '...'
    end

    local padding = max + 3 - #id
    return id .. string.rep(' ', padding) .. entry.label
end

M.makePickerEntry = function(max, entry)
    return {
        display = M.makeDisplay(max, entry),
        value = entry.id,
        ordinal = entry.id .. ' ' .. entry.label
    }
end


M.lastTable = nil

return M
