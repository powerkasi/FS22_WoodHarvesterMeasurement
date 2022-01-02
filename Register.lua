--[[
	Register.lua
	Author: powerkasi
]]

source(Utils.getFilename("hud/Enums.lua", g_currentModDirectory))
source(Utils.getFilename("hud/Styles.lua", g_currentModDirectory))
source(Utils.getFilename("hud/Card.lua", g_currentModDirectory))
source(Utils.getFilename("libs/json.lua", g_currentModDirectory))
source(Utils.getFilename("libs/Helper.lua", g_currentModDirectory))
source(Utils.getFilename("classes/Tree.lua", g_currentModDirectory))
source(Utils.getFilename("classes/Stand.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetCubicMetreTotalEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetCurrentDiameterEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetCurrentLengthEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetCutOnGoingEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetJSONObjectEvent.lua", g_currentModDirectory))
source(Utils.getFilename("events/SetTreeSpecieEvent.lua", g_currentModDirectory))
source(Utils.getFilename("gui/SettingsController.lua", g_currentModDirectory))
source(Utils.getFilename("WoodHarvesterMeasurement.lua", g_currentModDirectory))


local specName = "woodHarvesterMeasurement";
local className = "WoodHarvesterMeasurement";
local mainFile = "WoodHarvesterMeasurement.lua";
local modDirectory = g_currentModDirectory or ""
local modName = g_currentModName or "unknown"

---Register new specialization.
local function initSpecialization(manager)
    if manager.typeName == "vehicle" then
        g_specializationManager:addSpecialization(specName, className, modDirectory .. mainFile, nil)

        for typeName, typeEntry in pairs(g_vehicleTypeManager:getTypes()) do
            if SpecializationUtil.hasSpecialization(WoodHarvester, typeEntry.specializations) then
                g_vehicleTypeManager:addSpecialization(typeName, modName .. "."..specName)
            end
        end
    end
end

TypeManager.validateTypes = Utils.prependedFunction(TypeManager.validateTypes, initSpecialization)
