--[[
	Tree.lua
	Author: powerkasi
]]

Species = {
	UNKNOWN = 0,
	PINE = 1, -- mänty
	SPRUCE = 2 -- kuusi
}

SplitTypes = {
	UNKNOWN = 0,
	LOG = 1,
	PULPWOOD = 8
}

Tree = {
    specie = Species.UNKNOWN,
    totalCubeMetre = 0,
    totalLength = 0,
    splitCount = 0,
    splits = {}
}

function Tree:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self
    o.specie = o.specie or self.specie
    o.totalCubeMetre = o.totalCubeMetre or self.totalCubeMetre
    o.totalLength = o.totalLength or self.totalLength
    o.splitCount = o.splitCount or self.splitCount
    o.splits = o.splits or self.splits
    return o
end

function Tree:addSplit(split)
    table.insert(self.splits, split);
    self.totalCubeMetre = self.totalCubeMetre + split.cubeMetre
    self.totalLength = self.totalLength + split.length
    self.splitCount = self.splitCount + 1
end

function Tree.specieToString(specie)
    if specie == Species.PINE then
        return "Pine"
    elseif specie == Species.SPRUCE then
        return  "Spruce"
    else
        return "Unknown"
    end
end

function Tree.splitTypeToString(specie)
    if specie == SplitTypes.LOG then
        return "Log"
    elseif specie == SplitTypes.PULPWOOD then
        return  "Pulpwood"
    else
        return "Unknown"
    end
end

return Tree