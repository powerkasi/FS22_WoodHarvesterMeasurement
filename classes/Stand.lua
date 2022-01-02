--[[
	Stand.lua
	Author: powerkasi
]]

Stand = {
    splitCountStand 				= 0,
	splitCountPineLogStand 			= 0,
	splitCountPinePulpwoodStand 	= 0,
	splitCountSpruceLogStand		= 0,
	splitCountSprucePulpwoodStand 	= 0,
    splitCountUnknownLogStand		= 0,
	splitCountUnknownPulpwoodStand 	= 0,

	cubicMetreStand 				= 0.0,
	cubicMetrePineLogStand 			= 0.0,
	cubicMetrePinePulpwoodStand 	= 0.0,
	cubicMetreSpruceLogStand 		= 0.0,
	cubicMetreSprucePulpwoodStand 	= 0.0,
    cubicMetreUnknownLogStand 		= 0.0,
	cubicMetreUnknownPulpwoodStand 	= 0.0,

    maxNumberOfTrees                = 10,
    trees                           = {}
}

function Stand:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    o.splitCountStand = o.splitCountStand or self.splitCountStand
    o.splitCountPineLogStand = o.splitCountPineLogStand or self.splitCountPineLogStand
    o.splitCountPinePulpwoodStand = o.splitCountPinePulpwoodStand or self.splitCountPinePulpwoodStand
    o.splitCountSpruceLogStand = o.splitCountSpruceLogStand or self.splitCountSpruceLogStand
    o.splitCountSprucePulpwoodStand = o.splitCountSprucePulpwoodStand or self.splitCountSprucePulpwoodStand
    o.splitCountUnknownLogStand = o.splitCountUnknownLogStand or self.splitCountUnknownLogStand
    o.splitCountUnknownPulpwoodStand = o.splitCountUnknownPulpwoodStand or self.splitCountUnknownPulpwoodStand

    o.cubicMetreStand = o.cubicMetreStand or self.cubicMetreStand
    o.cubicMetrePineLogStand = o.cubicMetrePineLogStand or self.cubicMetrePineLogStand
    o.cubicMetrePinePulpwoodStand = o.cubicMetrePinePulpwoodStand or self.cubicMetrePinePulpwoodStand
    o.cubicMetreSpruceLogStand = o.cubicMetreSpruceLogStand or self.cubicMetreSpruceLogStand
    o.cubicMetreSprucePulpwoodStand = o.cubicMetreSprucePulpwoodStand or self.cubicMetreSprucePulpwoodStand
    o.cubicMetreUnknownLogStand = o.cubicMetreUnknownLogStand or self.cubicMetreUnknownLogStand
    o.cubicMetreUnknownPulpwoodStand = o.cubicMetreUnknownPulpwoodStand or self.cubicMetreUnknownPulpwoodStand

    o.maxNumberOfTrees = o.maxNumberOfTrees or self.maxNumberOfTrees
    o.trees = o.trees or self.trees
    return o
end

-- Updates last tree. Can be used to add split or just update tree.
function Stand:updateLastTree(tree, treeSpecieChanged)
    treeSpecieChanged = treeSpecieChanged or false
    self.trees[#self.trees] = tree

    if not treeSpecieChanged then
        self:updateStandStats()
    end
end

function Stand:addNewTree(tree)
    if #self.trees == self.maxNumberOfTrees then
        table.remove(self.trees, 1)
    end

    table.insert(self.trees, tree);
end

-- Store last split values for stand
function Stand:updateStandStats()
    local lastTree = self.trees[#self.trees]
    local lastSplit = lastTree.splits[#lastTree.splits]

    if lastSplit.treeType ~= SplitTypes.UNKNOWN then
        local specie, type = Tree.specieToString(lastTree.specie), Tree.splitTypeToString(lastSplit.treeType)
        self["splitCount"..specie..type.."Stand"] = self["splitCount"..specie..type.."Stand"] + 1
        self["cubicMetre"..specie..type.."Stand"] = self["cubicMetre"..specie..type.."Stand"] + lastSplit.cubeMetre
        self.splitCountStand = self.splitCountStand + 1
        self.cubicMetreStand = self.cubicMetreStand + lastSplit.cubeMetre
    end
end

function Stand:changeSpecie(specie)
    local lastTree = self.trees[#self.trees]
    local oldSpecie = Tree.specieToString(lastTree.specie)
    local newSpecie = Tree.specieToString(specie)

    for index, split in ipairs(lastTree.splits) do
        if split.treeType ~= SplitTypes.UNKNOWN then
            local type = Tree.splitTypeToString(split.treeType)
            self["splitCount"..oldSpecie..type.."Stand"] = self["splitCount"..oldSpecie..type.."Stand"] - 1
            self["splitCount"..newSpecie..type.."Stand"] = self["splitCount"..newSpecie..type.."Stand"] + 1
            self["cubicMetre"..oldSpecie..type.."Stand"] = self["cubicMetre"..oldSpecie..type.."Stand"] - split.cubeMetre
            self["cubicMetre"..newSpecie..type.."Stand"] = self["cubicMetre"..newSpecie..type.."Stand"] + split.cubeMetre
        end
    end
end

return Stand