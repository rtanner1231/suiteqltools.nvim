local M = {}

local idMap = nil

local function initializeMap()
    local Completion = require("suiteqltools.completion.completionData")
    local tableData = Completion.getTables()

    idMap = {}

    if tableData then
        for _, item in ipairs(tableData) do
            if item.id then
                idMap[item.id] = item.i
            end
        end
    end
end

---
-- Searches the preprocessed map for a specific id.
-- Lazily loads and processes the data on the first call.
-- @param idVal string: The id to search for
-- @return string|nil: The internal id 'i' or nil
---
function M.getInternalId(idVal)
    -- Lazy load: if idMap is nil, it's the first call, so we initialize
    if idMap == nil then
        initializeMap()
    end

    local result = idMap[idVal]

    if result and result ~= "" then
        return result
    end

    return nil
end

return M
