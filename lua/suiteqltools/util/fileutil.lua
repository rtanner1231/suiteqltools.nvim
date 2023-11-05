

local M={}

local Path=require('plenary.path')
local ScanDir=require('plenary.scandir')

M.pathcombine=function(path1,path2)
    return Path:new(path1):joinpath(path2).filename
end

M.getFileExt=function(filename)
  return filename:match("^.+(%..+)$")
end

M.getDirFromPath=function(full_path)
    local path_tokens={}
  for token in full_path:gmatch '[^/]+' do
    table.insert(path_tokens, token)
  end

    local len=#path_tokens

    table.remove(path_tokens,len)

    local ret=''

    for _,v in pairs(path_tokens) do
        ret=ret..'/'..v
    end

    return ret

end

M.fileExists=function(file_path)
    return Path:new(file_path):exists()
end


M.scanDir=function(dir)
    return ScanDir.scan_dir(dir,{depth=1})
end

M.scanDirDirectories=function(dir)
    return ScanDir.scan_dir(dir,{depth=1,only_dirs=true})
end


M.scanDirRecursive=function(dir)
    return ScanDir.scan_dir(dir)
end


M.readFile=function(path)
    return Path:new(path):read()
end

M.writeFile=function(path,content)
    Path:new(path):write(content,'w')
end

M.normalizePath=function(fullPath,cwd)
    return Path:new(fullPath):normalize(cwd)
end


return M
