local Config = require("suiteqltools.config")
local NSConn = require("nsconn")
local Common = require("suiteqltools.util.common")

local M = {}

M.runQuery = function(query, page)
	--local nsAccount=os.getenv('NS_ACCOUNT')

	--local nsAccount=os.getenv(Config.options.queryRun.envVars.nsAccount)

	local pageSize = Config.options.queryRun.pageSize
	local offset = (page - 1) * pageSize
	local requestBody = { q = query }
	local headers = { Prefer = "transient" }
	local success, result = NSConn.callSuiteTalk("/services/rest/query/v1/suiteql", {
		method = NSConn.Method.POST,
		body = requestBody,
		headers = headers,
		params = {
			limit = pageSize,
			offset = offset,
		},
	})

	if not success then
		local errorMessage = result

		--timeout is a common error.  Capture it
		if Common.stringContains(result, "was unable to complete in") then
			errorMessage = "Query timed out"
		end

		return {
			success = false,
			errorMessage = errorMessage,
			hasMore = false,
			total = 0,
		}
	end

	local body = vim.json.decode(result.body)
	local hasMore = body.hasMore
	local total = body.totalResults

	if body.items ~= nil then
		for _, v in ipairs(body.items) do
			v["links"] = nil
		end
		return {
			success = true,
			items = body.items,
			hasMore = hasMore,
			total = total,
		}
	else
		local errorMessage = ""

		if body["o:errorDetails"] then
			for _, v in ipairs(body["o:errorDetails"]) do
				errorMessage = errorMessage .. v["detail"]
			end
		else
			errorMessage = "Unknown error"
		end

		return {
			success = false,
			errorMessage = errorMessage,
			hasMore = hasMore,
			total = total,
		}
	end
end

return M
