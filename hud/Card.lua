--[[
	Card.lua
	Author: powerkasi
]]
--[[ Meta class ]]
-- Contains default values for new method
Card = {
    width = nil,
    height = nil,
    x = nil,
    y = nil,
    anchors = {
        centerIn = nil,
        horizontalCenter = nil,
        verticalCenter = nil,
        top = nil,
        left = nil,
        right = nil,
        bottom = nil,
        topMargin = 0.0,
        leftMargin = 0.0,
        rightMargin = 0.0,
        bottomMargin = 0.0
    },
    background = Utils.getFilename("hud/assets/bg.dds", g_currentModDirectory),
    backgroundColor = Colors.WHITE,
    backgroundOpacity = 0.3,
    text = "",
    fontSize = 0.015,
    fontColor = Colors.BLACK,
    textAlignment = RenderText.ALIGN_CENTER,
    textVerticalAlign = RenderText.VERTICAL_ALIGN_MIDDLE,
    -- "Read-Only"
    center = nil,
    top = nil,
    left = nil,
    right = nil,
    bottom = nil
}

--[[ New ]]
-- Method to create new instance
-- @param o (table)
function Card:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    for key, value in pairs(self.anchors) do
        o.anchors[key] = o.anchors[key] or value
    end

    --[[ Width ]]
    -- Can also be set by anchors if left and right anchors are set
    -- Priority order:
    --     1. width
    --     2. anchors
    if o.width ~= nil then
        o.width = o.width
    elseif o.anchors.left ~= nil and o.anchors.right ~= nil then
        o.width = o.anchors.right - o.anchors.left - o.anchors.leftMargin - o.anchors.rightMargin
    else
        o.width = self.width
    end

    --[[ Height ]]
    -- Can also be set by anchors if top and right anchors are set
    -- Priority order:
    --     1. height
    --     2. anchors
    if o.height ~= nil then
        o.height = o.height
    elseif o.anchors.top ~= nil and o.anchors.bottom ~= nil then
        o.height = o.anchors.bottom + o.anchors.top - o.anchors.topMargin - o.anchors.bottomMargin
    else
        o.height = self.height
    end

    --[[ Anchors ]]
    -- Are used if x, y coordinates are not set.

    -- anchors.centerIn
    if o.x == nil and o.y == nil then
        if o.anchors.centerIn ~= nil then
            o.x = o.anchors.centerIn.x - o.width / 2
            o.y = o.anchors.centerIn.y - o.height / 2
        end
    end
    -- anchors.horizontalCenter
    if o.x == nil then
        if o.anchors.horizontalCenter ~= nil then
            o.x = o.anchors.horizontalCenter - o.width / 2
        end
    end
    -- anchors.verticalCenter
    if o.y == nil then
        if o.anchors.verticalCenter ~= nil then
            o.y = o.anchors.verticalCenter - o.height / 2
        end
    end
    -- anchors.left/anchors.right
    if o.x == nil then
        if o.anchors.left ~= nil then
            o.x = o.anchors.left + o.anchors.leftMargin
        elseif o.anchors.right ~= nil then
            o.x = o.anchors.right - o.width - o.anchors.rightMargin
        else
            o.x = 0.0
        end
    else
        o.x = o.x -- Could this be removed?
    end
    -- anchors.top/anchors.bottom
    if o.y == nil then
        if o.anchors.top ~= nil then
            -- Renderer thinks that y is bottom of the object.
            -- So we need to reduce height and topMargin.
            o.y = o.anchors.top - o.height - o.anchors.topMargin
        elseif o.anchors.bottom ~= nil then
            o.y = o.anchors.bottom + o.anchors.bottomMargin
        else
            o.y = 0.0
        end
    else
        o.y = o.y -- Could this be removed?
    end

    o.background = o.background or self.background
    o.backgroundColor = o.backgroundColor or self.backgroundColor
    o.backgroundOpacity = o.backgroundOpacity or self.backgroundOpacity

    o.text = o.text or self.text
    o.fontSize = o.fontSize or self.fontSize
    o.fontColor = o.fontColor or self.fontColor
    o.textAlign = o.textAlignment or self.textAlignment
    o.textVerticalAlign = o.textVerticalAlign or self.textVerticalAlign
    o.textBottomMargin = o.textBottomMargin or self.textBottomMargin

    if o.width == nil then
        o.width = o:calculateTextWidth()
    end
    if o.height == nil then
        o.height = o:calculateTextHeight()
    end

    o.top = o:top()
    o.left = o:left()
    o.right = o:right()
    o.bottom = o:bottom()
    o.center = o:center()
    o.horizontalCenter = o.center.x
    o.verticalCenter = o.center.y

    o:render()
    return o
end

function Card:render()
    if self.background then
        local imageOverlay = createImageOverlay(self.background)
        setOverlayColor(
            imageOverlay,
            self.backgroundColor[1],
            self.backgroundColor[2],
            self.backgroundColor[3],
            self.backgroundOpacity
        )
        renderOverlay(imageOverlay, self.x, self.y, self.width, self.height)
    end

    if self.text then
        setTextAlignment(self.textAlignment)
        setTextVerticalAlignment(self.textVerticalAlign)
        setTextBold(true)
        setTextColor(self.fontColor[1], self.fontColor[2], self.fontColor[3], 1)
        renderText(self.x + self.width / 2, self.y + self.height / 2, self.fontSize, self.text)
    end
end

function Card:calculateTextWidth()
    if self.text ~= nil then
        return getTextWidth(self.fontSize, self.text)
    else
        return 0.0
    end
end

function Card:calculateTextHeight()
    if self.text ~= nil then
        return getTextHeight(self.fontSize, self.text)
    else
        return 0.0
    end
end

function Card:top()
    if self.y ~= nil then
        return self.y + self.height
    end
end

function Card:left()
    if self.x ~= nil then
        return self.x
    end
end

function Card:right()
    if self.x ~= nil then
        return self.x + self.width
    end
end

function Card:bottom()
    if self.y ~= nil then
        return self.y
    end
end

function Card:center()
    if self.x ~= nil and self.y ~= nil then
        return {x = self.x + self.width / 2, y = self.y + self.height / 2}
    end
end

function Card:verticalCenter()
    if self.x ~= nil then
        return self.x + self.width / 2
    end
end

function Card:horizontalCenter()
    if self.y ~= nil then
        return self.y + self.height / 2
    end
end

return Card
