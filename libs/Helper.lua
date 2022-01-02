--[[
	Helper.lua
	Author: powerkasi
]]

Helper = {}

-- Remove white spaces from string
function Helper.trim(str)
	return string.gsub(str, "%s+", "")
end

-- Separate 'object.property' string to table of two strings: { "object", "property" }
function Helper.parse(str)
    local ret = {};
    for s in str:gmatch("([^.]+)") do 
        table.insert(ret, s) 
    end
    return ret;
end

return Helper