--[[
	SettingsController.lua
	Author: powerkasi
]]

SettingsController = {}
local settingsController_mt = Class(SettingsController, ScreenElement)

function SettingsController.new(target, custom_mt, model)
    local self = ScreenElement.new(target, settingsController_mt)

    if model ~= nil then
        self.model = model;
    end

    self.returnScreenName = ""

    return self
end

function SettingsController:onOpen()
	SettingsController:superClass().onOpen(self)
    self:updateSpecSpecificRwValues();
    self:updateModSpecificRwValues();
    self:updateModSpecificRoValues();
end

-- Reload specialization specific Read-write values
function SettingsController:updateSpecSpecificRwValues()
    for key, value in pairs(self.specSpecificRwValues) do
        if self.specSpecificRwValues[key].text ~= tostring(self.model.spec_woodHarvester[key]) then
            self.specSpecificRwValues[key]:setText(tostring(self.model.spec_woodHarvester[key]));
        end
    end
end

-- Reload mod specific Read-write values from model
function SettingsController:updateModSpecificRwValues()
    for key, value in pairs(self.modSpecificRwValues) do
        local parsedElementName = Helper.parse(key);
        if table.getn(parsedElementName) == 1 then
            if self.modSpecificRwValues[key].text ~= tostring(self.model.spec_woodHarvesterMeasurement[key]) then
                self.modSpecificRwValues[key]:setText(tostring(string.format("%.2f", self.model.spec_woodHarvesterMeasurement[key])));
            end

        elseif table.getn(parsedElementName) == 2 then
            local object = json.decode(self.model.spec_woodHarvesterMeasurement[parsedElementName[1]]);
            local member = object[parsedElementName[2]];

            -- MultiTextOptions
            if self.modSpecificRwValues[key].typeName == "multiTextOption" then
                if self.modSpecificRwValues[key]:getState() ~= member then
                    self.modSpecificRwValues[key]:setState(member, false)
                end

            else -- radiusThresholds
                if self.modSpecificRwValues[key].text ~= member then
                    member = member / 0.01 -- to cm
                    self.modSpecificRwValues[key]:setText(tostring(member));
                end
            end
        end
    end
end

-- Reload mod specific Read-only values
function SettingsController:updateModSpecificRoValues()
    for key, value in pairs(self.modSpecificRoValues) do
        local parsedElementName = Helper.parse(key);

        if table.getn(parsedElementName) == 1 then
            if self.modSpecificRoValues[key].text ~= tostring(self.model.spec_woodHarvesterMeasurement[key]) then
                self.modSpecificRoValues[key]:setText(tostring(string.format("%.2f", self.model.spec_woodHarvesterMeasurement[key]).."m³"));
            end
        elseif table.getn(parsedElementName) == 2 then
            local object = json.decode(self.model.spec_woodHarvesterMeasurement[parsedElementName[1]]);
          
            if object == nil then
                g_logManager:error("updateModSpecificRoValues() - Cannot find:" ..parsedElementName[1].. ", from spec_woodHarvesterMeasurement.")
                return
            end

            local member = object[parsedElementName[2]];
            if member == nil then
                g_logManager:error("updateModSpecificRoValues() - Cannot find:" ..parsedElementName[2].. ", from object.")
                return
            end

            if string.find(parsedElementName[2], "splitCount") then
                self.modSpecificRoValues[key]:setText(tostring(member))
            else
                self.modSpecificRoValues[key]:setText(string.format("%.2f", member).."m³")
            end
        end
    end
end

function SettingsController:onCreateCustomText(element)
    self.customTexts = self.customTexts or {};

    if element.name then
        self.customTexts[element.name] = element;

        if element.name == "id" then
            self.customTexts[element.name]:setText(tostring(self.model.spec_woodHarvester.id));
        elseif element.name == "idNameModel" then
            self.customTexts[element.name]:setText("#"..tostring(self.model.spec_woodHarvester.id).." "..self.model:getFullName());
        end
    end
end

-- Bind to global specialization specific RW values
function SettingsController:onCreateSpecTextInput(element)
    self.specSpecificRwValues = self.specSpecificRwValues or {}
    if element.name then
        if self.model.spec_woodHarvester[element.name] ~= nil then
            self.specSpecificRwValues[element.name] = element
            self.specSpecificRwValues[element.name]:setText(tostring(self.model.spec_woodHarvester[element.name]));

            -- RWHM is setting these, so disable if installed
            if WoodHarvesterMeasurement.realWoodHarvesterSpec() ~= nil then
                self.specSpecificRwValues[element.name]:setDisabled(true)
            end
        else
            g_logManager:error("onCreateSpecTextInput() - Cannot create element: spec_woodHarvester doesn't contain "..element.name)
        end
    else
        g_logManager:error("onCreateSpecTextInput() - Cannot create element: element.name not defined.")
    end
end

-- Bind to mod specific RW values
function SettingsController:onCreateTextInput(element)
    self.modSpecificRwValues = self.modSpecificRwValues or {}
    if element.name then
        self.modSpecificRwValues[element.name] = element
        local parsedElementName = Helper.parse(element.name);

        -- Fetch toolTipText from translations if provided
        if element.toolTipText ~= nil then
            element.toolTipText = g_i18n:getText(element.toolTipText)
        end

        if table.getn(parsedElementName) == 1 then
            if self.model.spec_woodHarvesterMeasurement[element.name] ~= nil then
                self.modSpecificRwValues[element.name]:setText(tostring(self.model.spec_woodHarvesterMeasurement[element.name]));
            else
                g_logManager:error("onCreateTextInput() - Cannot create element: spec_woodHarvester doesn't contain "..element.name)
            end

        -- Currenlty only radiusThresholds
        elseif table.getn(parsedElementName) == 2 then
             -- Convert JSON object to an array
             local object = json.decode(self.model.spec_woodHarvesterMeasurement[parsedElementName[1]]);
             local member = object[parsedElementName[2]];
 
             if object == nil then
                 g_logManager:error("onCreateTextInput() - Cannot create element: spec_woodHarvester doesn't contain "..parsedElementName[1]);
                 return;
             elseif member == nil then
                 g_logManager:error("onCreateTextInput() - Cannot create element: spec_woodHarvester doesn't contain "..parsedElementName[2]);
                 return;
             end

             -- M to ccm
             member = member / 0.01
             self.modSpecificRwValues[element.name]:setText(tostring(member));
        end 
    else
        g_logManager:error("onCreateTextInput() - Cannot create element: element.name not defined.")
    end
end

-- Bind to mod specific RO values
function SettingsController:onCreateText(element)
    self.modSpecificRoValues = self.modSpecificRoValues or {}
    if element.name then
        self.modSpecificRoValues[element.name] = element
        local parsedElementName = Helper.parse(element.name);

        if table.getn(parsedElementName) == 1 then
            if self.model.spec_woodHarvesterMeasurement[element.name] == nil then
                g_logManager:error("onCreateText() - Cannot create element: spec_woodHarvester doesn't contain "..element.name)
                return;
            end

            if element.name == "splitCountStand" then
                element:setText(tostring(self.model.spec_woodHarvesterMeasurement[element.name]))
            else
                element:setText(string.format("%.2f", self.model.spec_woodHarvesterMeasurement[element.name]).."m³")
            end
        elseif table.getn(parsedElementName) == 2 then
            -- Convert JSON object to an array
            local object = json.decode(self.model.spec_woodHarvesterMeasurement[parsedElementName[1]]);
            local member = object[parsedElementName[2]];

            if object == nil then
                g_logManager:error("onCreateText() - Cannot create element: spec_woodHarvester doesn't contain "..parsedElementName[1]);
                return;
            elseif member == nil then
                g_logManager:error("onCreateText() - Cannot create element: spec_woodHarvester doesn't contain "..parsedElementName[2]);
                return;
            end

            if string.find(parsedElementName[2], "splitCount") then
                element:setText(tostring(member))
            else
                element:setText(string.format("%.2f", member).."m³")
            end
        end
    else
        g_logManager:error("onCreateText() - Cannot create element: element.name not defined.")
    end
end

-- Deprecated
-- function SettingsController:onCreateTranslatedText(element)
--     if element then
--         element:setText(g_i18n:getText(element.text))
--     else
--         g_logManager:error("onCreateTranslatedText() - Cannot create element: Element not defined.")
--     end
-- end

function SettingsController:onCreateMultiTextOption(element)
    self.modSpecificRwValues = self.modSpecificRwValues or {}
    if element.name then
        self.modSpecificRwValues[element.name] = element
        element.text = g_i18n:getText(element.text)

        if element.name == "hudConfigs.position" then
            element.toolTipText = g_i18n:getText('WOODHARVESTERMEASUREMENT_HUD_POSITION_TOOLTIP')
            local values = {
                g_i18n:getText(string.format("WOODHARVESTERMEASUREMENT_HUD_POSITION_%s", HUDPosition.BOTTOMCENTER)),
                g_i18n:getText(string.format("WOODHARVESTERMEASUREMENT_HUD_POSITION_%s", HUDPosition.BOTTOMRIGHT))
            }

            element:setTexts(values)
        elseif element.name == "hudConfigs.offsetX" then
            element.toolTipText = g_i18n:getText('WOODHARVESTERMEASUREMENT_HUD_OFFSET_TOOLTIP')
            local values = {
                tostring(0),
                tostring(10),
                tostring(20),
                tostring(30),
                tostring(40),
                tostring(50),
                tostring(60),
                tostring(70),
                tostring(80),
            }

            element:setTexts(values)
        end
    end
end

function SettingsController:onClickBack()
    SettingsController:superClass().onClickBack(self)
end

function SettingsController:onClickSave()
    -- Save specialization specific values
    for key, value in pairs(self.specSpecificRwValues) do
        local newValue = tonumber(self.specSpecificRwValues[key].text)
        if self.model.spec_woodHarvester[key] ~= newValue and newValue > 0 then
            self.model.spec_woodHarvester[key] = tonumber(self.specSpecificRwValues[key].text);
        end
    end

    self:saveModSpecificRwValues();
end

-- Save mod specific RW values
function SettingsController:saveModSpecificRwValues()
    -- Convert JSON object to an array
    local newhudConfigs = json.decode(self.model.spec_woodHarvesterMeasurement.hudConfigs)
    local newRadiusThresholds = json.decode(self.model.spec_woodHarvesterMeasurement.radiusThresholds)

     for key, value in pairs(self.modSpecificRwValues) do
        local element =  self.modSpecificRwValues[key]

        local parsedElementName = Helper.parse(key);
        if table.getn(parsedElementName) == 1 then
            if self.model.spec_woodHarvesterMeasurement[key] ~= tonumber(self.modSpecificRwValues[key].text) then
                self.model.spec_woodHarvesterMeasurement[key] = tonumber(self.modSpecificRwValues[key].text);
            end
        elseif table.getn(parsedElementName) == 2 then

            -- MultiTextOptions
            if element.typeName == "multiTextOption" then
                local state = element:getState()
                if newhudConfigs[parsedElementName[2]] ~= state then
                    newhudConfigs[parsedElementName[2]] = state
                end
            end

            if parsedElementName[1] == "radiusThresholds" then
                local newValue = tonumber(self.modSpecificRwValues[key].text) * 0.01
                if newRadiusThresholds[parsedElementName[2]] ~= newValue and newValue > 0 then
                    newRadiusThresholds[parsedElementName[2]] = newValue;
                end
            end
        end
    end

    WoodHarvesterMeasurement.setHUDConfigs(self.model, json.encode(newhudConfigs))
    WoodHarvesterMeasurement.setRadiusThresholds(self.model, json.encode(newRadiusThresholds))
end

function SettingsController:onClickUndoButton()
    self:updateSpecSpecificRwValues();
    self:updateModSpecificRwValues();
end

function SettingsController:onClickResetDefaultButton()
    if WoodHarvesterMeasurement.realWoodHarvesterSpec() == nil then
        -- Reset global specialization specific values
        for key, value in pairs(self.specSpecificRwValues) do
            if self.specSpecificRwValues[key].text ~= tostring(WoodHarvesterMeasurement.defaults[key]) then
                self.specSpecificRwValues[key]:setText(tostring(WoodHarvesterMeasurement.defaults[key]));
            end
        end
    end

    -- Reset mod specific values
    for key, value in pairs(self.modSpecificRwValues) do
        local parsedElementName = Helper.parse(key);
        if table.getn(parsedElementName) == 2 then
            if parsedElementName[1] == "radiusThresholds" then
                local resetValue = tostring(json.decode(WoodHarvesterMeasurement.defaultRadiusThresholds)[parsedElementName[2]] / 0.01 )
                if self.modSpecificRwValues[key].text ~= resetValue then
                    self.modSpecificRwValues[key]:setText(resetValue);
                end
            end
        end
    end
end

function SettingsController:onClickResetStandStats()
    WoodHarvesterMeasurement.resetStand(self.model);
    self:updateModSpecificRoValues();
end

function SettingsController:onCreateHelpText(element)
    if element ~= nil and element.name ~= nil then
        self[element.name] = self[element.name] or element
    end
end

function SettingsController:onHelpTextChanged()
    if self["helpText"].text ~= "" then
        self["helpElement"]:setVisible(true)
    else
        self["helpElement"]:setVisible(false)
    end
end