local Config= require('suiteqltools.config')
local FormatSuiteQL=require('suiteqltools.formatsuiteql')

local M={}

M.runFormatCurrent=FormatSuiteQL.runFormatCurrent
M.runFormatAll=FormatSuiteQL.runFormatAll

M.setup=Config.setup

return M
