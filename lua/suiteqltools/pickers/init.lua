local Config = require("suiteqltools.config")

local function get_installed_plugin()
    local snacks_ok, _ = pcall(require, "snacks")

    if snacks_ok then
        return "snacks"
    end

    local telescope_ok, _ = pcall(require, "telescope")
    if telescope_ok then
        return "telescope"
    end

    return ''
end

local provider = ''
local providedLoaded = false

local get_provider = function()
    if providedLoaded then
        return provider
    end

    if Config.options.picker == 'auto' then
        provider = get_installed_plugin()
    else
        provider = Config.options.picker
    end
    providedLoaded = true
    return provider
end

local M = {}

local show_error = function(msg)
    vim.notify(msg, vim.log.levels.ERROR)
end

---@opts
---items: {[any: any],preview?: {text: string}}[]
---format?: {type: 'field' | string, value: string, highlight?: "Label" | "Comment" }[]
---title: string
---customActions?: {closePicker: boolean, action: (item)=>void,keyMap:string, name: string}
---defaultAction?: {action: (item)=>void}
---previewFT?: string --file type of preview
---showPreview: boolean
---searchValue?: (item)=>string
---justifyColumns?: boolean -- If true, aligns columns vertically
M.show_picker = function(opts)
    local pick_provider = get_provider()
    if pick_provider == '' then
        show_error('No picker provider found')
    end

    if (pick_provider == 'snacks') then
        require('suiteqltools.pickers.providers.snacks').show_picker(opts)
    elseif (pick_provider == 'telescope') then
        require('suiteqltools.pickers.providers.telescope').show_picker(opts)
    else
        show_error('Invalid picker provider')
    end
end

return M
