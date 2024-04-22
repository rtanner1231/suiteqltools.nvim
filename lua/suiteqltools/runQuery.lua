local Config = require("suiteqltools.config")
local NSConn = require("nsconn")
local Common = require("suiteqltools.util.common")
local Restlet = require("suiteqltools.util.restlet")

local M = {}

local runSuiteTalk = function(query, pageSize, offset)
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
			type = Restlet.ServiceType.SUITETALK,
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
			type = Restlet.ServiceType.SUITETALK,
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
			type = Restlet.ServiceType.SUITETALK,
		}
	end
end

local runRestlet = function(query, pageSize, offset, opts)
	local requestBody = {
		query = query,
		limit = pageSize,
		offset = offset,
	}

	print(vim.inspect(requestBody))

	local success, result = NSConn.callRestlet(opts.scriptId, opts.deploymentId, {
		method = NSConn.Method.POST,
		body = requestBody,
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
			type = Restlet.ServiceType.RESTLET,
		}
	end

	local body = vim.json.decode(result.body)

	if not body.success then
		return {
			success = false,
			errorMessage = body.errorMessage,
			hasMore = false,
			total = 0,
			type = Restlet.ServiceType.RESTLET,
		}
	end

	return {
		success = true,
		items = body.results,
		hasMore = true,
		total = 0,
		type = Restlet.ServiceType.RESTLET,
	}
end

M.runQuery = function(query, page)
	--local nsAccount=os.getenv('NS_ACCOUNT')

	--local nsAccount=os.getenv(Config.options.queryRun.envVars.nsAccount)

	local pageSize = Config.options.queryRun.pageSize
	local offset = (page - 1) * pageSize

	local serviceTypeObj = Restlet.getServiceType()

	if serviceTypeObj.serviceType == Restlet.ServiceType.RESTLET then
		return runRestlet(
			query,
			pageSize,
			offset,
			{ scriptId = serviceTypeObj.scriptId, deploymentId = serviceTypeObj.deploymentId }
		)
	else
		return runSuiteTalk(query, pageSize, offset)
	end
end

return M
