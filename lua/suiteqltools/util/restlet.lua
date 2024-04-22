local NSConn = require("nsconn")

local M = {}

local appName = "SUITEQLTOOLS"
local useRestletKey = "USERESTLET"
local scriptIdKey = "RESTLETSCRIPTID"
local deploymentIdKey = "RESTLETDEPLOYMENTID"
M.ServiceType = {
	SUITETALK = "SuiteTalk",
	RESTLET = "Restlet",
}

M.getServiceType = function()
	local useRestlet = NSConn.getCustomValue(appName, useRestletKey)
	local scriptId = NSConn.getCustomValue(appName, scriptIdKey)
	local deploymentId = NSConn.getCustomValue(appName, deploymentIdKey)

	local type

	if useRestlet then
		type = M.ServiceType.RESTLET
	else
		type = M.ServiceType.SUITETALK
	end

	return {
		serviceType = type,
		scriptId = scriptId,
		deploymentId = deploymentId,
	}
end

M.useRestlet = function()
	local serviceOpts = M.getServiceType()

	if serviceOpts.scriptId ~= nil and serviceOpts.deploymentId ~= nil then
		local useExisting = vim.fn.input("Use existing script id? ([y]/n)")
		if useExisting == "y" or useExisting == "Y" or useExisting == "" or useExisting == nil then
			NSConn.setCustomValue(appName, useRestletKey, true)
		end
		return
	end

	local nilOrEmpty = function(val)
		return val == nil or val == "" or val == " "
	end
	local scriptId = vim.fn.input("Script Id ")
	if nilOrEmpty(scriptId) then
		return
	end

	local deploymentId = vim.fn.input("Deployment Id ")
	if nilOrEmpty(deploymentId) then
		return
	end

	NSConn.setCustomValue(appName, useRestletKey, true)
	NSConn.setCustomValue(appName, scriptIdKey, scriptId)
	NSConn.setCustomValue(appName, deploymentIdKey, deploymentId)
end

M.useSuiteTalk = function()
	NSConn.setCustomValue(appName, useRestletKey, false)
end

return M
