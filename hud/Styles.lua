--[[
	Styles.lua
	Author: powerkasi
]]

Styles = {
	hudTypes = {
		bottomCenter = {
			bottomMargin = 25,
			width = 256,
			height = 224, -- 64 + 64 / 2 + 64 / 1.5 * 3
			bigCardWidth = 128, -- 0.05
			bigCardheight = 64, -- 0.05
		},
		bottomRight = {
			bottomMargin = 25,
			width = 256,
			height = 224, -- 64 + 64 / 2 + 64 / 1.5 * 3
			bigCardWidth = 128, -- 0.05
			bigCardheight = 64, -- 0.05
		}
	},

	hudStyles = {
		ponsse = {
			backgroundColor 			= Colors.WHITE,
			backgroundOpacity 			= 0.3,
			cutOnGoingBackgroundOpacity = 0.8,
			pineBackgroundColor			= Colors.PONSSE_BLUE,
			spruceBackgroundColor		= Colors.PONSSE_GREEN,
			highlightBackGroundColor	= Colors.PONSSE_YELLOW,
			fontColor					= Colors.BLACK
		},
		komatsu = {
			backgroundColor 			= Colors.KOMATSU_DARKBLUE,
			backgroundOpacity 			= 0.3,
			cutOnGoingBackgroundOpacity = 0.8,
			pineBackgroundColor			= Colors.BLUE,
			spruceBackgroundColor		= Colors.GREEN,
			highlightBackGroundColor	= Colors.KOMATSU_DARKBLUE,
			fontColor					= Colors.KOMATSU_YELLOW
		},
		johndeere = {
			backgroundColor 			= Colors.WHITE,
			backgroundOpacity 			= 0.3,
			cutOnGoingBackgroundOpacity = 0.8,
			pineBackgroundColor			= Colors.BLUE,
			spruceBackgroundColor		= Colors.GREEN,
			highlightBackGroundColor	= Colors.YELLOW,
			fontColor					= Colors.BLACK
		},
		default = {
			-- sideHudBottomMargin			= 0.35,
			-- centerHudBottomMargin 		= 0.154,
			backgroundColor 			= Colors.WHITE,
			backgroundOpacity 			= 0.3,
			cutOnGoingBackgroundOpacity = 0.8,
			pineBackgroundColor			= Colors.BLUE,
			spruceBackgroundColor		= Colors.GREEN,
			highlightBackGroundColor	= Colors.YELLOW,
			fontColor					= Colors.BLACK
		}
	}
}

return Styles