local Picker = require('snacks').picker

local M = {}

local hightlightMapping = {
    Label = "SnacksPickerLabel",
    Comment = "SnacksPickerComment"
}

local make_actions = function(customActions)
    if customActions == nil then
        return {}
    end

    local actions = {}

    for _, action in ipairs(customActions) do
        actions[action.name] = function(picker, item)
            if action.closePicker then
                picker:close()
            end

            action.action(item)
        end
    end

    return actions
end

local make_keys = function(customActions)
    if customActions == nil then
        return {}
    end

    local keys = {}

    for _, action in ipairs(customActions) do
        keys[action.keyMap] = { action.name, mode = { "n", "i" } }
    end

    return keys
end

-- Helper to extract the string value for a specific format definition
local get_fmt_value = function(item, fmt)
    if fmt.type == "field" then
        return tostring(item[fmt.value] or "")
    elseif fmt.type == "string" then
        return fmt.value
    elseif fmt.type == "func" then
        return tostring(fmt.value(item) or "")
    end
    return ""
end

---@opts
---items: {[any: any]}[]
---format?: {type: 'field' | 'string' | 'func', value: string | (item)=>string, highlight?: "Label" | "Comment" }[]
---title: string
---customActions?: {closePicker: boolean, action: (item)=>void,keyMap:string, name: string}
---defaultAction?: {action: (item)=>void}
---previewFT?: string --file type of preview
---showPreview: boolean
---previewValue?: (item)=>string
---searchValue?: (item)=>string
---justifyColumns?: boolean -- If true, aligns columns vertically

local make_options = function(opts)
    local pickerOptions = {}

    local items = opts.items

    if (opts.showPreview and opts.previewFT) or opts.searchValue then
        items = vim.fn.map(items, function(_, item)
            -- Add preview filetype if needed
            item.preview = item.preview or {}
            if opts.showPreview and opts.previewFT and item.preview ~= nil then
                item.preview.ft = opts.previewFT
                if opts.previewValue then
                    item.preview.text = opts.previewValue(item)
                else
                    item.preview.text = 'No previewValue provided'
                end
            end

            -- If searchValue is provided, use it to set the 'text' field
            if opts.searchValue then
                item.text = opts.searchValue(item)
            end

            return item
        end)
    end

    pickerOptions.title = opts.title
    pickerOptions.items = items

    -- Pre-calculate column widths if justification is enabled
    local col_widths = {}
    if opts.justifyColumns and opts.format then
        -- Initialize widths
        for i = 1, #opts.format do
            col_widths[i] = 0
        end

        -- Calculate max width for each column
        for _, item in ipairs(items) do
            for i, fmt in ipairs(opts.format) do
                local val = get_fmt_value(item, fmt)
                local len = vim.fn.strdisplaywidth(val)
                if len > col_widths[i] then
                    col_widths[i] = len
                end
            end
        end
    end

    if opts.format ~= nil then
        local format = function(item)
            local ret_line = {}

            for i, fmt in ipairs(opts.format) do
                local segment = {}
                local val = get_fmt_value(item, fmt)

                -- Apply Padding if enabled
                -- We skip padding on the very last column (i < #opts.format)
                if opts.justifyColumns and i < #opts.format then
                    local len = vim.fn.strdisplaywidth(val)
                    local target_width = col_widths[i]

                    if target_width and target_width > len then
                        val = val .. string.rep(" ", target_width - len)
                    end
                end

                table.insert(segment, val)

                if fmt.highlight ~= nil then
                    table.insert(segment, hightlightMapping[fmt.highlight])
                end

                table.insert(ret_line, segment)
            end

            return ret_line
        end
        pickerOptions.format = format
    end

    pickerOptions.confirm = function(picker, item)
        picker:close()
        if opts.defaultAction ~= nil then
            opts.defaultAction(item)
        end
    end

    pickerOptions.actions = make_actions(opts.customActions)

    if opts.showPreview then
        pickerOptions.preview = "preview"
    else
        pickerOptions.layout = { preview = false }
    end

    pickerOptions.win = {
        input = {
            keys = make_keys(opts.customActions),
        },

        preview = {
            wo = {
                wrap = true,
                linebreak = true,
            },
        },
    }

    return pickerOptions
end

M.show_picker = function(opts)
    local pickerOptions = make_options(opts)

    Picker.pick(pickerOptions)
end


-- local project_items = {
--     {
--         name = "Dotfiles",
--         path = "/home/user/projects/dotfiles",
--         id = "dotfiles-proj",
--         description = "Personal Neovim configuration and shell scripts.",
--         docs_url = "httpsD://github.com/user/dotfiles/README.md",
--     },
--     {
--         name = "My App",
--         path = "/home/user/projects/my-app",
--         id = "myapp-proj",
--         description = "Main work project, written in Go.\nContains multiple modules.",
--         docs_url = "https://internal.company.com/docs/my-app",
--     },
--     {
--         name = "Blog",
--         path = "/var/www/blog",
--         id = "blog-proj",
--         description = "Personal blog content.\nNeeds update.",
--         docs_url = "https://my-blog.com/admin",
--
--     },
-- }
--
-- M.show_picker({
--     items = project_items,
--     format = {
--         {
--             type = 'func',
--             value = function(item)
--                 return item.name .. ' ' .. item.id
--             end
--             ,
--             highlight = 'Label'
--         },
--         { type = 'string', value = '  ' },
--         { type = 'field',  value = 'docs_url', highlight = 'Comment' }
--     },
--     defaultAction = function(item)
--         print('Confirmed with ' .. item.name)
--     end,
--     customActions = {
--         {
--             name = 'open_docs',
--             action = function(item)
--                 print('Opening docs at ' .. item.docs_url)
--             end,
--             keyMap = '<C-d>',
--             closePicker = true
--         },
--     },
--     showPreview = true,
--     previewFT = 'sql',
--     previewValue = function(item)
--         return item.description
--     end,
--     searchValue = function(item)
--         return item.name .. item.description .. item.docs_url
--     end,
--     justifyColumns = true
-- })


return M
