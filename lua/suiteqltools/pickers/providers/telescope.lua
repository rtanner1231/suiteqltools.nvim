local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local previewers = require("telescope.previewers")
local actions = require("telescope.actions")
local state = require("telescope.actions.state")
local entry_display = require("telescope.pickers.entry_display")
local conf = require("telescope.config").values

local M = {}

local hightlightMapping = {
    Label = "TelescopeResultsType",
    Comment = "TelescopeResultsComment",
}

local replace_newlines = function(str)
    return string.gsub(str, "\r?\n", " ")
end

local get_item_value = function(val)
    return replace_newlines(val)
end

--Create the table which contains the column layout widths
local make_display_items = function(opts)
    local display_items = {}

    if opts.format then
        for n, fmt in ipairs(opts.format) do
            if n == #opts.format then
                table.insert(display_items, { remaining = true })
            else
                if fmt.type == "field" then
                    local maxLen = math.max(
                        unpack(
                            vim.fn.map(opts.items, function(_, i)
                                local val = get_item_value(i[fmt.value])
                                return vim.fn.strdisplaywidth(val)
                            end)
                        )
                    )

                    table.insert(display_items, {
                        width = maxLen,
                    })
                elseif fmt.type == "string" then
                    local width = vim.fn.strdisplaywidth(get_item_value(fmt.value))
                    table.insert(display_items, {
                        width = width
                    })
                elseif fmt.type == 'func' then
                    local maxLen = math.max(
                        unpack(
                            vim.fn.map(opts.items, function(_, i)
                                local val = get_item_value(fmt.value(i))
                                return vim.fn.strdisplaywidth(val)
                            end)
                        )
                    )
                    table.insert(display_items, {
                        width = maxLen,
                    })
                else
                    table.insert(display_items, { width = 1 })
                end
            end
        end
    else
        table.insert(display_items, {
            remaining = true,
        })
    end

    return display_items
end

-- Helper to create the list of { text, highlight } parts
local make_formatted_items = function(opts, entry_object)
    local result = {}

    for _, v in ipairs(opts.format) do
        local value = {}
        local text = ""

        if v.type == "field" then
            text = get_item_value(entry_object.item[v.value] or "")
        elseif v.type == "string" then
            text = get_item_value(v.value)
        elseif v.type == 'func' then
            text = get_item_value(v.value(entry_object.item) or "")
        else
            text = ' '
        end

        table.insert(value, text)

        if v.highlight then
            table.insert(value, hightlightMapping[v.highlight])
        end

        table.insert(result, value)
    end

    return result
end

local make_display = function(opts)
    if opts.justifyColumns then
        local display_items = make_display_items(opts)

        local separator = opts.format and "" or " "
        local displayer = entry_display.create({
            separator = separator,
            items = display_items,
        })

        return function(entry_object)
            local displayer_object = make_formatted_items(opts, entry_object)
            return displayer(displayer_object)
        end

        --not justfied columns
    else
        return function(entry_object)
            local parts = make_formatted_items(opts, entry_object)

            local final_str = ""
            local highlights = {}

            for _, part in ipairs(parts) do
                local text = part[1]
                local hl_group = part[2]

                -- Calculate byte offsets for Telescope highlights
                local start_pos = #final_str
                final_str = final_str .. text
                local end_pos = #final_str

                if hl_group and text ~= "" then
                    table.insert(highlights, { { start_pos, end_pos }, hl_group })
                end
            end

            return final_str, highlights
        end
    end
end


---
--- Creates the entry_maker function for the finder.
--- This function is responsible for processing the `opts.format`
--- table to create the display for each row in the picker.
---
---@param opts table The picker options
---@return function
local function make_entry_maker(opts)
    local display_func = make_display(opts)

    return function(item)
        local search_text = ''

        if opts.searchValue then
            search_text = opts.searchValue(item)
        end

        return {
            value = search_text,
            ordinal = search_text,
            display = display_func,
            item = item,
        }
    end
end

--- Public function to show the picker.
---
---@opts
---items: {[any: any],preview?: {text: string}}[]
---format?: {type: 'field' | 'string' | 'func', value: string | (item)=>string, highlight?: "Label" | "Comment" }[]
---title: string
---customActions?: {closePicker: boolean, action: (item)=>void,keyMap:string, name: string}
---defaultAction?: {action: (item)=>void}
---previewFT?: string --file type of preview
---showPreview: boolean
---previewValue: (item)=>string
---searchValue: (item)=>string
---justifyColumns?: boolean -- If true, aligns columns vertically
function M.show_picker(opts)
    local picker_options = {
        prompt_title = opts.title or "Select Item",
    }

    picker_options.finder = finders.new_table({
        results = opts.items,
        entry_maker = make_entry_maker(opts),
    })

    picker_options.sorter = conf.generic_sorter(opts)

    if opts.showPreview then
        local previewer = previewers.new_buffer_previewer({
            title = "Preview",
            define_preview = function(self, entry, status)
                local bufnr = self.state.bufnr
                local item = entry.item -- Get our original item
                if not opts.previewValue then
                    local pretty_item = vim.inspect(item)
                    local lines = vim.split(pretty_item, "\n")
                    vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
                    vim.bo[bufnr].filetype = "lua"
                    return
                end

                local lines = vim.split(opts.previewValue(item), "\n")
                vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)

                if opts.previewFT then
                    vim.bo[bufnr].filetype = opts.previewFT
                end

                vim.wo[self.state.winid].wrap = true
                vim.wo[self.state.winid].linebreak = true
            end,
        })
        picker_options.previewer = previewer
    end

    picker_options.attach_mappings = function(prompt_bufnr, map)
        if opts.defaultAction then
            local function do_default_action()
                local selection = state.get_selected_entry()
                actions.close(prompt_bufnr)
                opts.defaultAction(selection.item)
            end
            map("i", "<CR>", do_default_action)
            map("n", "<CR>", do_default_action)
        end

        -- Custom Actions
        if opts.customActions then
            for _, action_def in ipairs(opts.customActions) do
                local function do_custom_action()
                    local selection = state.get_selected_entry()
                    if action_def.closePicker then
                        actions.close(prompt_bufnr)
                    end
                    action_def.action(selection.item)
                end
                map("i", action_def.keyMap, do_custom_action)
                map("n", action_def.keyMap, do_custom_action)
            end
        end

        return true
    end

    local picker = pickers.new(picker_options)
    picker:find()
end

-- local project_items = {
--     {
--         name = "Dotfiles",
--         path = "/home/user/projects/dotfiles",
--         id = "dotfiles-proj",
--         description = "Personal Neovim configuration and shell scripts.",
--         docs_url = "httpsD://github.com/user/dotfiles/README.md",
--         preview = { text = "Dots" },
--     },
--     {
--         name = "My App",
--         path = "/home/user/projects/my-app",
--         id = "myapp-proj",
--         description = "Main work project, written in Go.\nContains multiple modules.",
--         docs_url = "https://internal.company.com/docs/my-app",
--         preview = { text = "Aps" },
--     },
--     {
--         name = "Blog",
--         path = "/var/www/blog",
--         id = "blog-proj",
--         description = "Personal blog content.\nNeeds update.",
--         docs_url = "https://my-blog.com/admin",
--         preview = { text = "select\n* from location" },
--     },
-- }
--
-- M.show_picker({
--     items = project_items,
--     title = "Select a Project",
--     format = {
--         {
--             type = 'func',
--             value = function(item)
--                 return item.name .. ' ' .. item.id
--             end
--             ,
--             highlight = 'label'
--         },
--         { type = "string", value = "  " },
--         { type = "field",  value = "docs_url", highlight = "Comment" },
--     },
--     defaultAction = function(item)
--         print("Confirmed with " .. item.name)
--     end,
--     customActions = {
--         {
--             name = "open_docs",
--             action = function(item)
--                 print("Opening docs at " .. item.docs_url)
--             end,
--             keyMap = "<C-d>",
--             closePicker = true,
--         },
--     },
--     showPreview = true,
--     previewFT = "sql",
--     previewValue = function(item)
--         return item.description
--     end,
--     searchValue = function(item)
--         return item.name .. item.description .. item.docs_url
--     end,
--     justifyColumns = true
-- })

return M
