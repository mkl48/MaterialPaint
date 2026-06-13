-- MaterialPaint
-- Types.lua
-- Plinko Labs

export type Platform = "Console" | "Mobile" | "Computer"

export type Mode = "Button" | "Axis" | "Combo" | "Shortcut"
	| "Hold" | "Charge" | "DoubleTap" | "Mash" | "LongPress" | "Gesture"

export type State = "Pressed" | "Released" | "Held" | "Changed"
	| "Triggered" | "Canceled" | "Charged" | "Stepped" | "Moved"
	| "DoubleTapped" | "LongPressed" | "Mashed" | "Conflicted"
	| "Enabled" | "Disabled"

export type PollState = "Idle" | "Active" | "Held"

export type Driver = "IAS" | "CAS" | "UIS"

export type InputEvent = {
	Source:   Enum.KeyCode | Enum.UserInputType,
	State:    State,
	Delta:    Vector2?,
	Position: Vector2?,
	Progress: number?,
	Count:    number?,
	Step:     number?,
	Held:     boolean,
	Consumed: boolean,
	Consume:  (self: InputEvent) -> (),
}

export type BindingConfig = {
	KeyCode:   (Enum.KeyCode | Enum.UserInputType)?,
	Modifier:  Enum.KeyCode?,
	Platforms: { Platform }?,
}

export type ActionConfig = {
	Bindings:       { Enum.KeyCode | Enum.UserInputType | BindingConfig }?,
	Contexts:       { string }?,
	Driver:         Driver?,
	Mode:           Mode?,
	Sequence:       { Enum.KeyCode | Enum.UserInputType }?,
	Window:         number?,
	HoldTime:       number?,
	MashThreshold:  number?,
	Deadzone:       number?,
	RepeatInterval: number?,
	Priority:       number?,
	Platforms:      { Platform }?,
	Tags:           { string }?,
}

export type Connection = {
	Then:    (self: Connection, cb: (any) -> any) -> Connection,
	Catch:   (self: Connection, cb: (any) -> ()) -> Connection,
	Once:    (self: Connection) -> Connection,
	Await:   (self: Connection) -> (boolean, any),
	Destroy: (self: Connection) -> (),
}

export type ActionHandle = {
	Name:        string,
	Config:      ActionConfig,
	Next:        (self: ActionHandle, state: State) -> Connection,
	HoldFor:     (self: ActionHandle, seconds: number) -> Connection,
	Poll:        (self: ActionHandle) -> PollState,
	IsHeld:      (self: ActionHandle) -> boolean,
	HeldDuration:(self: ActionHandle) -> number,
	Enable:      (self: ActionHandle) -> (),
	Disable:     (self: ActionHandle) -> (),
	Destroy:     (self: ActionHandle) -> (),
}

return {}
