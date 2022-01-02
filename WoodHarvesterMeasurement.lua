--[[
	WoodHarvesterMeasurement.lua
	Author: powerkasi
]]
local modDirectory = g_currentModDirectory

WoodHarvesterMeasurement = {}

WoodHarvesterMeasurement.hudTypes = Styles.hudTypes
WoodHarvesterMeasurement.hudStyles = Styles.hudStyles

WoodHarvesterMeasurement.defaults = {
	-- cutMaxRadius = 0, -- H6 = D60cm, DH7 = 70cm
	cutLengthMin = 1.0, -- GIATN's default
	cutLengthMax = 8.0, -- GIATN's default
	cutLengthStep = 1. -- GIATN's default
}

WoodHarvesterMeasurement.defaulHUDConfigs =
	json.encode(
	{
		position = HUDPosition.BOTTOMCENTER,
		offsetX = HUDOffset.DEFAULT
	}
)

WoodHarvesterMeasurement.defaultRadiusThresholds =
	json.encode(
	{
		pineLogMinRadius = 0.16,
		pinePulpwoodMinRadius = 0.06,
		spruceLogMinRadius = 0.16,
		sprucePulpwoodMinRadius = 0.07,
		fallbackLogMinRadius = 0.16,
		fallbackPulpwoodMinRadius = 0.06
	}
)

function WoodHarvesterMeasurement.prerequisitesPresent(specializations)
	return true
end

function WoodHarvesterMeasurement.initSpecialization()
	local schema = Vehicle.xmlSchema
	schema:setXMLSpecializationType()
	local schemaSavegame = Vehicle.xmlSchemaSavegame
	schemaSavegame:register(
		XMLValueType.FLOAT,
		"vehicles.vehicle(?).FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#cubicMetreTotal",
		"Total cubic metres",
		0
	)
	schemaSavegame:register(
		XMLValueType.STRING,
		"vehicles.vehicle(?).FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#radiusThresholds",
		"Radius thresholds"
	)
	schemaSavegame:register(
		XMLValueType.STRING,
		"vehicles.vehicle(?).FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#hudConfigs",
		"HUD configs"
	)
	schemaSavegame:register(
		XMLValueType.STRING,
		"vehicles.vehicle(?).FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#currentStand",
		"Current stand statistics"
	)
end

-- This function is copied from FS22_guidanceSteering mod by Wopster
function WoodHarvesterMeasurement:mergeModTranslations(i18n)
	-- We can copy all our translations to the global table because
	-- we prefix everything with WOODHARVESTERMEASUREMENT_
	local modEnvMeta = getmetatable(_G)
	local env = modEnvMeta.__index

	local global = env.g_i18n.texts
	for key, text in pairs(i18n.texts) do
		global[key] = text
	end
end

function WoodHarvesterMeasurement.registerEventListeners(vehicleType)
	local functionNames = {
		"onLoad",
		"saveToXMLFile",
		"onCutTree",
		"onDeactivate",
		"onTurnedOn",
		"onTurnedOff",
		"onUpdate",
		"onDraw",
		"onWriteStream",
		"onReadStream",
		"onRegisterActionEvents"
	}

	for _, functionName in ipairs(functionNames) do
		SpecializationUtil.registerEventListener(vehicleType, functionName, WoodHarvesterMeasurement)
	end
end

function WoodHarvesterMeasurement.registerFunctions(vehicleType)
	local newFunctions = {
		"setCubicMetreTotal",
		"setCurrentDiameter",
		"onBeforeCutTree",
		"setCurrentLength",
		"setCutOnGoing",
		"setTreeSpecie",
		"setJSONObjectValue",
		"addNewSplit",
		"drawHUD",
		"getVehicleBrand",
		"mergeModTranslations",
		"scalePixelToScreenWidth",
		"scalePixelToScreenHeight"
	}

	for _, newFunction in ipairs(newFunctions) do
		SpecializationUtil.registerFunction(vehicleType, newFunction, WoodHarvesterMeasurement[newFunction])
	end
end

function WoodHarvesterMeasurement:onLoad(savegame)
	self.spec_woodHarvesterMeasurement = {}
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	-- Values that are sync between server and client
	specWoodHarvesterMeasurement.currentDiameter = 0
	specWoodHarvesterMeasurement.currentLength = 0
	specWoodHarvesterMeasurement.cutOnGoing = false
	specWoodHarvesterMeasurement.treeSpecie = Species.UNKNOWN
	specWoodHarvesterMeasurement.currentTree = json.encode(Tree:new())

	-- Values only for server side
	specWoodHarvesterMeasurement.previousCutRadius = 0
	specWoodHarvesterMeasurement.previousCutY = 0

	-- Stored values
	if savegame ~= nil then
		specWoodHarvesterMeasurement.cubicMetreTotal =
			savegame.xmlFile:getValue(
			savegame.key .. ".FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#cubicMetreTotal",
			0
		)
		specWoodHarvesterMeasurement.radiusThresholds =
			savegame.xmlFile:getValue(
			savegame.key .. ".FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#radiusThresholds",
			WoodHarvesterMeasurement.defaultRadiusThresholds
		)
		specWoodHarvesterMeasurement.hudConfigs =
			savegame.xmlFile:getValue(
			savegame.key .. ".FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#hudConfigs",
			WoodHarvesterMeasurement.defaulHUDConfigs
		)
		specWoodHarvesterMeasurement.currentStand =
			savegame.xmlFile:getValue(
			savegame.key .. ".FS22_WoodHarvesterMeasurement.woodHarvesterMeasurement#currentStand",
			json.encode(Stand:new())
		)
	else
		specWoodHarvesterMeasurement.cubicMetreTotal = 0.0
		specWoodHarvesterMeasurement.radiusThresholds = WoodHarvesterMeasurement.defaultRadiusThresholds
		specWoodHarvesterMeasurement.hudConfigs = WoodHarvesterMeasurement.defaulHUDConfigs
		specWoodHarvesterMeasurement.currentStand = json.encode(Stand:new())
	end

	-- Support legacy versions
	local decodedHudConfigs = json.decode(specWoodHarvesterMeasurement.hudConfigs)
	if decodedHudConfigs.offsetX == nil then
		decodedHudConfigs.offsetX = json.decode(WoodHarvesterMeasurement.defaulHUDConfigs).offsetX
		specWoodHarvesterMeasurement.hudConfigs = json.encode(decodedHudConfigs)
	end

	-- prependedFunction() prepend an existing function with the given function or if the original
	-- function does not exist then only the new one will be returned.
	-- So if need to execute something before the original function you use this.
	self.setLastTreeDiameter =
		Utils.prependedFunction(self.setLastTreeDiameter, WoodHarvesterMeasurement.setCurrentDiameter)

	-- local specRealWoodHarvester = WoodHarvesterMeasurement.realWoodHarvesterSpec()
	-- if specRealWoodHarvester ~= nil then
	-- specRealWoodHarvester.cutTreeNew = Utils.prependedFunction(specRealWoodHarvester.cutTreeNew, WoodHarvesterMeasurement.onBeforeCutTree);
	-- else
	self.cutTree = Utils.prependedFunction(self.cutTree, WoodHarvesterMeasurement.onBeforeCutTree)
	-- end

	self:mergeModTranslations(g_i18n)

	-- GUI
	if self.isClient then
		if specWoodHarvesterMeasurement.gui == nil then
			g_gui:loadProfiles(modDirectory .. "gui/guiProfiles.xml")
			specWoodHarvesterMeasurement.gui = {}
			specWoodHarvesterMeasurement.gui["settingController"] = SettingsController.new(nil, nil, self)

			-- Description
			-- Load a UI screen view's elements from an XML definition.
			-- Definition
			-- loadGui(xmlFilename View, name Screen, controller FrameElement, isFrame [optional,)
			g_gui:loadGui(
				modDirectory .. "gui/settingsGui.xml",
				"settingsGui",
				specWoodHarvesterMeasurement.gui.settingController
			)
		end
	end
end

function WoodHarvesterMeasurement:onRegisterActionEvents(isActiveForInput)
	if self.isClient then
		local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

		if specWoodHarvesterMeasurement.actionEvents == nil then
			specWoodHarvesterMeasurement.actionEvents = {}
		end

		self:clearActionEventsTable(specWoodHarvesterMeasurement.actionEvents)

		if self:getIsActiveForInput(true) then
			local _, actionEventId =
				self:addActionEvent(
				specWoodHarvesterMeasurement.actionEvents,
				InputAction.WHM_OPEN_SETTINGS,
				self,
				WoodHarvesterMeasurement.actionOpenSettings,
				false,
				true,
				false,
				true,
				nil
			)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, true)
			g_inputBinding:setActionEventActive(actionEventId, false)

			_, actionEventId =
				self:addActionEvent(
				specWoodHarvesterMeasurement.actionEvents,
				InputAction.WHM_SET_TREE_SPECIE_TO_PINE,
				self,
				WoodHarvesterMeasurement.actionEventSetTreeSpecieToPine,
				false,
				true,
				false,
				true,
				nil
			)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, true)
			g_inputBinding:setActionEventActive(actionEventId, false)

			_, actionEventId =
				self:addActionEvent(
				specWoodHarvesterMeasurement.actionEvents,
				InputAction.WHM_SET_TREE_SPECIE_TO_SPRUCE,
				self,
				WoodHarvesterMeasurement.actionEventSetTreeSpecieToSpruce,
				false,
				true,
				false,
				true,
				nil
			)
			g_inputBinding:setActionEventTextPriority(actionEventId, GS_PRIO_HIGH)
			g_inputBinding:setActionEventTextVisibility(actionEventId, true)
			g_inputBinding:setActionEventActive(actionEventId, false)
		end
	end
end

function WoodHarvesterMeasurement.actionOpenSettings(self, actionName, inputValue, callbackState, isAnalog)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	if specWoodHarvesterMeasurement.gui.settingController ~= nil then
		if specWoodHarvesterMeasurement.gui.settingController.isOpen then
			-- Close settings
			specWoodHarvesterMeasurement.gui.settingController:onClickBack()
		elseif g_gui.currentGui == nil and specWoodHarvesterMeasurement.gui.settingController.isOpen ~= true then
			-- Display a screen identified by name.
			specWoodHarvesterMeasurement.gui["settingController"] = SettingsController.new(nil, nil, self)
			g_gui:loadGui(
				modDirectory .. "gui/settingsGui.xml",
				"settingsGui",
				specWoodHarvesterMeasurement.gui.settingController
			)
			g_gui:showGui("settingsGui")
		end
	end
end

function WoodHarvesterMeasurement.resetStand(self)
	self:setJSONObjectValue("currentStand", json.encode(Stand:new()))
end

function WoodHarvesterMeasurement.setRadiusThresholds(self, value)
	self:setJSONObjectValue("radiusThresholds", value)
end

function WoodHarvesterMeasurement.setHUDConfigs(self, value)
	self:setJSONObjectValue("hudConfigs", value)
end

function WoodHarvesterMeasurement.actionEventSetTreeSpecieToPine(self, actionName, inputValue, callbackState, isAnalog)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	self:setTreeSpecie(Species.PINE)
end

function WoodHarvesterMeasurement.actionEventSetTreeSpecieToSpruce(self, actionName, inputValue, callbackState, isAnalog)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	self:setTreeSpecie(Species.SPRUCE)
end

-- When tree cutting happening
function WoodHarvesterMeasurement:onCutTree(radius)
	if self.isServer then
		local spec = self.spec_woodHarvester
		local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

		local previousCutRadius = specWoodHarvesterMeasurement.previousCutRadius
		local attachedSplitShapeLastCutY = spec.attachedSplitShapeLastCutY
		local attachedSplitShapeY = spec.attachedSplitShapeY

		-- Got new split; calculate cubicMetreTotals
		if previousCutRadius ~= 0 then
			local length
			local averageRadius

			self:setCurrentLength((spec.attachedSplitShapeY - specWoodHarvesterMeasurement.previousCutY) * 100)

			if radius ~= 0 then -- Normal case, when it cuts the split
				length = (attachedSplitShapeLastCutY - specWoodHarvesterMeasurement.previousCutY)
				averageRadius = ((specWoodHarvesterMeasurement.previousCutRadius + radius) / 2)
			else -- Case if split never got cutted
				length = attachedSplitShapeY - specWoodHarvesterMeasurement.previousCutY
				averageRadius = ((specWoodHarvesterMeasurement.previousCutRadius + (spec.lastDiameter / 2)) / 2)
			end

			-- Just make sure to skip negative values
			local skipMeasurement = length <= 0 or averageRadius <= 0

			if not skipMeasurement then
				self:addNewSplit(length, averageRadius)
			end
		else -- Create new tree
			local newCurrentTree =
				json.encode(
				Tree:new(
					{
						specie = specWoodHarvesterMeasurement.treeSpecie
					}
				)
			)
			self:setJSONObjectValue("currentTree", newCurrentTree)

			-- Add new tree into stand
			local currentStand = Stand:new(json.decode(specWoodHarvesterMeasurement.currentStand))
			currentStand:addNewTree(json.decode(newCurrentTree))
			self:setJSONObjectValue("currentStand", json.encode(currentStand))
		end

		-- Store for next cut calculations
		specWoodHarvesterMeasurement.previousCutRadius = radius
		specWoodHarvesterMeasurement.previousCutY = attachedSplitShapeLastCutY

		self:setCurrentLength(0)
		self:setCutOnGoing(false)
	end
end

function WoodHarvesterMeasurement:addNewSplit(length, averageRadius)
	local spec = self.spec_woodHarvester
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	local cubeMetre = (math.pi * math.pow(averageRadius, 2) * length)
	self:setCubicMetreTotal(specWoodHarvesterMeasurement.cubicMetreTotal + cubeMetre)

	local treeType
	local radiusThresholds = json.decode(specWoodHarvesterMeasurement.radiusThresholds)

	-- Pine
	if specWoodHarvesterMeasurement.treeSpecie == Species.PINE then
		-- Spruce
		if spec.lastDiameter >= radiusThresholds.pineLogMinRadius then
			treeType = SplitTypes.LOG
		elseif spec.lastDiameter >= radiusThresholds.pinePulpwoodMinRadius then
			treeType = SplitTypes.PULPWOOD
		else
			treeType = SplitTypes.UNKNOWN
		end
	elseif specWoodHarvesterMeasurement.treeSpecie == Species.SPRUCE then
		-- Fallback
		if spec.lastDiameter >= radiusThresholds.spruceLogMinRadius then
			treeType = SplitTypes.LOG
		elseif spec.lastDiameter >= radiusThresholds.sprucePulpwoodMinRadius then
			treeType = SplitTypes.PULPWOOD
		else
			treeType = SplitTypes.UNKNOWN
		end
	else
		if spec.lastDiameter >= radiusThresholds.fallbackLogMinRadius then
			treeType = SplitTypes.LOG
		elseif spec.lastDiameter >= radiusThresholds.fallbackPulpwoodMinRadius then
			treeType = SplitTypes.PULPWOOD
		else
			treeType = SplitTypes.UNKNOWN
		end
	end

	if treeType ~= SplitTypes.UNKNOWN then
		local currentStand = Stand:new(json.decode(specWoodHarvesterMeasurement.currentStand))
		local currentTree = Tree:new(json.decode(specWoodHarvesterMeasurement.currentTree))
		currentTree:addSplit(
			{
				n = currentStand.splitCountStand + 1,
				treeType = treeType,
				cubeMetre = cubeMetre,
				length = length,
				diameter = spec.lastDiameter
			}
		)
		self:setJSONObjectValue("currentTree", json.encode(currentTree))

		-- Update current tree for stand
		currentStand:updateLastTree(currentTree)
		self:setJSONObjectValue("currentStand", json.encode(currentStand))
	end
end

function WoodHarvesterMeasurement:scalePixelToScreenWidth(px)
	w, h = getNormalizedScreenValues(px * g_gameSettings.uiScale, g_screenHeight * g_gameSettings.uiScale)
	return w
end

function WoodHarvesterMeasurement:scalePixelToScreenHeight(px)
	w, h = getNormalizedScreenValues(g_screenWidth * g_gameSettings.uiScale, px * g_gameSettings.uiScale)
	return h
end

-- Draw HUD
function WoodHarvesterMeasurement:drawHUD()
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	local textLength = string.format("%.0f", specWoodHarvesterMeasurement.currentLength)
	local textDiameter = string.format("%.0f", specWoodHarvesterMeasurement.currentDiameter * 1000)
	local specieString = WoodHarvesterMeasurement.treeSpecieToString(self, specWoodHarvesterMeasurement.treeSpecie)

	local brand = Helper.trim(string.lower(self:getVehicleBrand().name))
	local style = WoodHarvesterMeasurement.hudStyles["default"]

	local hudConfigs = json.decode(specWoodHarvesterMeasurement.hudConfigs)
	local hudType
	if hudConfigs.position == HUDPosition.BOTTOMCENTER then
		hudType = WoodHarvesterMeasurement.hudTypes.bottomCenter
	else
		hudType = WoodHarvesterMeasurement.hudTypes.bottomRight
	end

	if WoodHarvesterMeasurement.hudStyles[brand] ~= nil then
		style = WoodHarvesterMeasurement.hudStyles[brand]
	end

	local backgroundColor, backgroundOpacity = style.backgroundColor, style.backgroundOpacity

	if specWoodHarvesterMeasurement.cutOnGoing then
		if specWoodHarvesterMeasurement.treeSpecie == Species.PINE then
			backgroundColor = style.pineBackgroundColor
		elseif specWoodHarvesterMeasurement.treeSpecie == Species.SPRUCE then
			backgroundColor = style.spruceBackgroundColor
		else
			backgroundColor = Colors.RED
		end
		backgroundOpacity = style.cutOnGoingBackgroundOpacity
	end

	local parent =
		Card:new(
		{
			x = 0.0, -- screen.left
			y = 0.0, -- screen.bottom
			width = 1.0, -- fill screen
			height = 1.0, -- fill screen
			backgroundOpacity = 0.0
		}
	)

	local containerdW = hudType.width or 0
	local containerH = hudType.height or 0
	local offSetX = parent.height / 2 * (((hudConfigs.offsetX - 1) * 10) / 100)
	local bottomMargin = self:scalePixelToScreenHeight(hudType.bottomMargin or 0) + offSetX

	containerdW, containerH =
		getNormalizedScreenValues(hudType.width * g_gameSettings.uiScale, hudType.height * g_gameSettings.uiScale)

	local hudContainer
	local speedMeterX, speedMeterY = g_currentMission.hud.speedMeter.gearElement:getPosition()

	if hudType == WoodHarvesterMeasurement.hudTypes.bottomCenter then
		hudContainer =
			Card:new(
			{
				anchors = {
					horizontalCenter = parent.horizontalCenter,
					bottom = parent.bottom,
					bottomMargin = bottomMargin / g_gameSettings.uiScale
				},
				width = containerdW,
				height = containerH,
				backgroundOpacity = 0.0
			}
		)
	else
		hudContainer =
			Card:new(
			{
				anchors = {
					right = speedMeterX + g_currentMission.hud.speedMeter.gearElement:getWidth(),
					bottom = speedMeterY + g_currentMission.hud.speedMeter.gearElement:getHeight(),
					bottomMargin = bottomMargin
				},
				width = containerdW,
				height = containerH,
				backgroundOpacity = 0.0
			}
		)
	end

	local diameterCardW, diameterCardH =
		getNormalizedScreenValues(
		hudType.bigCardWidth * g_gameSettings.uiScale,
		hudType.bigCardheight * g_gameSettings.uiScale
	)

	-- Current diameter
	local diameterCard =
		Card:new(
		{
			anchors = {
				top = hudContainer.top,
				right = hudContainer.right
			},
			width = diameterCardW,
			height = diameterCardH,
			fontSize = self:scalePixelToScreenHeight(32),
			 --diameterCardH / 2,
			fontColor = style.fontColor,
			text = textDiameter,
			backgroundColor = backgroundColor,
			backgroundOpacity = backgroundOpacity or 0.3
		}
	)

	-- Current length
	local lengthCard =
		Card:new(
		{
			anchors = {
				top = diameterCard.top,
				right = diameterCard.left
			},
			width = diameterCard.width,
			height = diameterCard.height,
			fontSize = diameterCard.fontSize,
			fontColor = style.fontColor,
			text = textLength,
			backgroundColor = backgroundColor,
			backgroundOpacity = backgroundOpacity or 0.3
		}
	)

	-- Tree specie card
	local specieCard =
		Card:new(
		{
			anchors = {
				top = lengthCard.bottom,
				left = lengthCard.left
			},
			width = diameterCard.width,
			height = diameterCard.height / 2,
			fontSize = diameterCard.fontSize / 2,
			fontColor = style.fontColor,
			text = specieString,
			backgroundColor = style.backgroundColor
		}
	)

	-- Current tree status
	local statusCubeMetre, statusLength = 0, 0
	local currentTree = json.decode(specWoodHarvesterMeasurement.currentTree)
	if currentTree ~= nil then
		statusCubeMetre = currentTree.totalCubeMetre or 0
		statusLength = currentTree.totalLength or 0
	end

	local currentTreeStatusCard =
		Card:new(
		{
			anchors = {
				top = diameterCard.bottom,
				right = diameterCard.right
			},
			width = diameterCard.width,
			height = diameterCard.height / 2,
			fontSize = diameterCard.fontSize / 2.5,
			fontColor = style.fontColor,
			text = string.format("%.0f", (statusCubeMetre * 1000)) ..
				"L\n" .. string.format("%.0f", (statusLength * 100)) .. "cm",
			backgroundColor = style.highlightBackGroundColor,
			backgroundOpacity = 0.7
		}
	)

	-- Cutted split cards
	if currentTree.splitCount > 0 then
		local previousSplitX = specieCard.x
		local cardsPerRow = 3
		local cardCounter = 0
		local row = 1
		local cardWidth = diameterCard.width * 2 / cardsPerRow
		local cardHeight = diameterCard.height / 1.5

		local startIndex = 1
		if #currentTree.splits > 9 then
			startIndex = startIndex + (#currentTree.splits - 9)
		end

		for index, data in ipairs(currentTree.splits) do
			if index >= startIndex then
				local splitCard =
					Card:new(
					{
						x = previousSplitX,
						width = cardWidth,
						height = cardHeight,
						fontColor = style.fontColor,
						fontSize = diameterCard.fontSize / cardsPerRow,
						y = specieCard.y - cardHeight * row,
						backgroundColor = style.backgroundColor,
						text = tostring(data.treeType) ..
							":" ..
								WoodHarvesterMeasurement.treeTypeToString(self, data.treeType) ..
									" " ..
										string.format("%.0f", (data.cubeMetre * 1000)) ..
											"L\n" ..
												string.format("%.0f", (data.length * 100)) ..
													"cm/" .. string.format("%.0f", data.diameter * 1000) .. "mm\n" .. "#" .. tostring(data.n)
					}
				)

				cardCounter = cardCounter + 1

				if cardCounter >= cardsPerRow then
					row = row + 1
					cardCounter = 0
					previousSplitX = specieCard.x
				else
					previousSplitX = previousSplitX + cardWidth
				end
			end
		end
	end

	-- Need to restore vertical alignment always - GIANT's bug?
	setTextVerticalAlignment(RenderText.VERTICAL_ALIGN_BASELINE)
end

function WoodHarvesterMeasurement:onDraw()
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	-- HELP TEXTS
	local actionEvent = specWoodHarvesterMeasurement.actionEvents[InputAction.WHM_OPEN_SETTINGS]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
		g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("input_WHM_OPEN_SETTINGS"))
	end

	actionEvent = specWoodHarvesterMeasurement.actionEvents[InputAction.WHM_SET_TREE_SPECIE_TO_PINE]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
		g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("input_WHM_SET_TREE_SPECIE_TO_PINE"))
	end

	actionEvent = specWoodHarvesterMeasurement.actionEvents[InputAction.WHM_SET_TREE_SPECIE_TO_SPRUCE]
	if actionEvent ~= nil then
		g_inputBinding:setActionEventActive(actionEvent.actionEventId, true)
		g_inputBinding:setActionEventText(actionEvent.actionEventId, g_i18n:getText("input_WHM_SET_TREE_SPECIE_TO_SPRUCE"))
	end

	self:drawHUD()
end

function WoodHarvesterMeasurement.treeSpecieToString(self, treeSpecie)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	if treeSpecie == Species.PINE then
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_PINE")
	elseif treeSpecie == Species.SPRUCE then
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_SPRUCE")
	else
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_UNKNOWN_SPECIE")
	end
end

function WoodHarvesterMeasurement.treeTypeToString(self, treeType)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	if treeType == SplitTypes.LOG then
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_LOG")
	elseif treeType == SplitTypes.PULPWOOD then
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_PULPWOOD")
	else
		return g_i18n:getText("WOODHARVESTERMEASUREMENT_UNKNOWN_TREE_TYPE")
	end
end

-- When jumps out or into another vehicle
function WoodHarvesterMeasurement:onDeactivate()
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	-- specWoodHarvesterMeasurement.previousCutRadius = 0
end

-- When cutter head will turn off
function WoodHarvesterMeasurement:onTurnedOff()
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	specWoodHarvesterMeasurement.previousCutRadius = 0
end

function WoodHarvesterMeasurement:onTurnedOn()
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	specWoodHarvesterMeasurement.previousCutRadius = 0
end

function WoodHarvesterMeasurement:onUpdate()
	local spec = self.spec_woodHarvester
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if spec.attachedSplitShape ~= nil and spec.isAttachedSplitShapeMoving then
		if specWoodHarvesterMeasurement.currentDiameter ~= 0 then
			self:setCurrentLength((spec.attachedSplitShapeY - specWoodHarvesterMeasurement.previousCutY) * 100)
		end
	end
end

function WoodHarvesterMeasurement:onBeforeCutTree(length, noEventSend)
	cutTree, noEventSend = cutTree, noEventSend
	local spec = self.spec_woodHarvester
	if self.isServer then
		if length == 0 then
			if spec.attachedSplitShape ~= nil or spec.curSplitShape ~= nil then
				self:setCutOnGoing(true)
			end
		end
	end
end

-- TODO: this function is currently disabled since RWHM is not released yet.
function WoodHarvesterMeasurement.realWoodHarvesterSpec()
	-- local typeEntry = g_vehicleTypeManager.vehicleTypes["woodHarvester"]
	-- if typeEntry ~= nil then
	-- 	local spec = typeEntry.specializationsByName["RealWoodHarvester"]
	--       if spec ~= nil then
	-- 		return spec
	-- 	end
	-- end
	return nil
end

-- get brand table
-- 		key: isMod, 			e.g. value:false
-- 		key: image, 			e.g. value:data/store/brands/brand_ponsse.png
-- 		key: index, 			e.g. value:79
-- 		key: title, 			e.g. value:PONSSE
-- 		key: name,  			e.g. value:PONSSE
-- 		key: imageShopOverview,	e.g. value:data/store/brands/brand_ponsse.pn
function WoodHarvesterMeasurement:getVehicleBrand()
	local storeItem = g_storeManager:getItemByXMLFilename(self.configFileName)
	if storeItem ~= nil then
		local brand = g_brandManager:getBrandByIndex(storeItem.brandIndex)
		if brand ~= nil then
			return brand
		end
	end
end

-- Called on client side on join ??
function WoodHarvesterMeasurement:onWriteStream(streamId, connection)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	streamWriteFloat32(streamId, specWoodHarvesterMeasurement.cubicMetreTotal)
	streamWriteString(streamId, specWoodHarvesterMeasurement.radiusThresholds)
	streamWriteString(streamId, specWoodHarvesterMeasurement.hudConfigs)
	streamWriteString(streamId, specWoodHarvesterMeasurement.currentStand)
end

-- Called on server side on join ??
function WoodHarvesterMeasurement:onReadStream(streamId, connection)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	specWoodHarvesterMeasurement.cubicMetreTotal = streamReadFloat32(streamId)
	specWoodHarvesterMeasurement.radiusThresholds = streamReadString(streamId)
	specWoodHarvesterMeasurement.hudConfigs = streamReadString(streamId)
	specWoodHarvesterMeasurement.currentStand = streamReadString(streamId)
end

function WoodHarvesterMeasurement:saveToXMLFile(xmlFile, key)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement
	xmlFile:setValue(key .. "#cubicMetreTotal", specWoodHarvesterMeasurement.cubicMetreTotal)
	xmlFile:setValue(key .. "#radiusThresholds", specWoodHarvesterMeasurement.radiusThresholds)
	xmlFile:setValue(key .. "#hudConfigs", specWoodHarvesterMeasurement.hudConfigs)
	xmlFile:setValue(key .. "#currentStand", specWoodHarvesterMeasurement.currentStand)
end

--[[
	EVENTS START
]]
function WoodHarvesterMeasurement:setCubicMetreTotal(cubicMetreTotal, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if cubicMetreTotal ~= specWoodHarvesterMeasurement.cubicMetreTotal then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetCubicMetreTotalEvent.new(self, cubicMetreTotal), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SetCubicMetreTotalEvent.new(self, cubicMetreTotal))
			end
		end

		specWoodHarvesterMeasurement.cubicMetreTotal = cubicMetreTotal
	end
end

function WoodHarvesterMeasurement:setCurrentDiameter(currentDiameter, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if currentDiameter ~= specWoodHarvesterMeasurement.currentDiameter then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetCurrentDiameterEvent.new(self, currentDiameter), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SetCurrentDiameterEvent.new(self, currentDiameter))
			end
		end

		specWoodHarvesterMeasurement.currentDiameter = currentDiameter
	end
end

function WoodHarvesterMeasurement:setCurrentLength(currentLength, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if currentLength ~= specWoodHarvesterMeasurement.currentLength then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetCurrentLengthEvent.new(self, currentLength), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SetCurrentLengthEvent.new(self, currentLength))
			end
		end

		specWoodHarvesterMeasurement.currentLength = currentLength
	end
end

function WoodHarvesterMeasurement:setCutOnGoing(cutOnGoing, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if cutOnGoing ~= specWoodHarvesterMeasurement.cutOnGoing then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetCutOnGoingEvent.new(self, cutOnGoing), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SetCutOnGoingEvent.new(self, cutOnGoing))
			end
		end

		specWoodHarvesterMeasurement.cutOnGoing = cutOnGoing
	end
end

function WoodHarvesterMeasurement:setTreeSpecie(treeSpecie, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if treeSpecie ~= specWoodHarvesterMeasurement.treeSpecie then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetTreeSpecieEvent.new(self, treeSpecie), nil, nil, self)
			else
				g_client:getServerConnection():sendEvent(SetTreeSpecieEvent.new(self, treeSpecie))
			end
		end

		specWoodHarvesterMeasurement.treeSpecie = treeSpecie

		local currentTree = json.decode(specWoodHarvesterMeasurement.currentTree)
		if currentTree.splitCount > 0 then
			-- Change also specie into treeSplits
			currentTree.specie = specWoodHarvesterMeasurement.treeSpecie
			self:setJSONObjectValue("currentTree", json.encode(currentTree))

			-- Change specie for stand
			local currentStand = Stand:new(json.decode(specWoodHarvesterMeasurement.currentStand))
			currentStand:changeSpecie(specWoodHarvesterMeasurement.treeSpecie)
			currentStand:updateLastTree(currentTree, true)
			self:setJSONObjectValue("currentStand", json.encode(currentStand))
		end
	end
end

function WoodHarvesterMeasurement:setJSONObjectValue(property, value, noEventSend)
	local specWoodHarvesterMeasurement = self.spec_woodHarvesterMeasurement

	if value ~= specWoodHarvesterMeasurement[property] then
		if not noEventSend then
			if g_server ~= nil then
				g_server:broadcastEvent(SetJSONObjectEvent.new(self, property, value), nil, nil, self)
			else -- Client set value and send event
				g_client:getServerConnection():sendEvent(SetJSONObjectEvent.new(self, property, value))
			end
		end
		specWoodHarvesterMeasurement[property] = value
	end
end
--[[ 
	EVENTS END
]]
