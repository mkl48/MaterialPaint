-- MaterialPaint
-- Enums.lua
-- Plinko Labs

local Enums = {}

export type State =
	"Pressed"
	| "Released"
	| "Held"
	| "Changed"
	| "Triggered"
	| "Canceled"
	| "Charged"
	| "Stepped"
	| "Moved"
	| "DoubleTapped"
	| "LongPressed"
	| "Mashed"
	| "Conflicted"
	| "Enabled"
	| "Disabled"

export type Mode =
	"Button"
	| "Axis"
	| "Combo"
	| "Shortcut"
	| "Hold"
	| "Charge"
	| "DoubleTap"
	| "Mash"
	| "LongPress"
	| "Gesture"

export type Platform = "Console" | "Mobile" | "Computer"

export type Poll = "Idle" | "Active" | "Held"

export type Driver = "IAS" | "CAS" | "UIS"

Enums.State = {
	Pressed = "Pressed",
	Released = "Released",
	Held = "Held",
	Changed = "Changed",
	Triggered = "Triggered",
	Canceled = "Canceled",
	Charged = "Charged",
	Stepped = "Stepped",
	Moved = "Moved",
	DoubleTapped = "DoubleTapped",
	LongPressed = "LongPressed",
	Mashed = "Mashed",
	Conflicted = "Conflicted",
	Enabled = "Enabled",
	Disabled = "Disabled",
} :: { [string]: State }

Enums.Mode = {
	Button = "Button",
	Axis = "Axis",
	Combo = "Combo",
	Shortcut = "Shortcut",
	Hold = "Hold",
	Charge = "Charge",
	DoubleTap = "DoubleTap",
	Mash = "Mash",
	LongPress = "LongPress",
	Gesture = "Gesture",
} :: { [string]: Mode }

Enums.Platform = {
	Console = "Console",
	Mobile = "Mobile",
	Computer = "Computer",
} :: { [string]: Platform }

Enums.Poll = {
	Idle = "Idle",
	Active = "Active",
	Held = "Held",
} :: { [string]: Poll }

Enums.Driver = {
	IAS = "IAS",
	CAS = "CAS",
	UIS = "UIS",
} :: { [string]: Driver }

return Enums
