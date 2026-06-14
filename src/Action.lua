-- MaterialPaint
-- Action.lua
-- Plinko Labs

local ContextActionService = game:GetService("ContextActionService")
local UserInputService     = game:GetService("UserInputService")
local RunService           = game:GetService("RunService")

local Enums      = require(script.Parent.Enums)
local Context    = require(script.Parent.Context)
local Connection = require(script.Parent.Connection).Connection

local Action = {}
Action.__index = Action

local function _makeSignalTable()
	return setmetatable({}, {
		__index = function(t, k)
			t[k] = {}
			return t[k]
		end,
	})
end

local function _makeEvent(
	source: Enum.KeyCode | Enum.UserInputType,
	state: Enums.State,
	extra: { [string]: any }?
)
	local event = {
		Source   = source,
		State    = state,
		Delta    = extra and extra.Delta,
		Position = extra and extra.Position,
		Progress = extra and extra.Progress,
		Count    = extra and extra.Count,
		Step     = extra and extra.Step,
		Held     = extra and extra.Held or false,
		Consumed = false,
	}

	function event:Consume()
		self.Consumed = true
	end

	return event
end

function Action.new(name: string, config: any)
	local self = setmetatable({}, Action)

	self.Name         = name
	self.Config       = config
	self._signals     = _makeSignalTable()
	self._driver      = config.Driver or Enums.Driver.IAS
	self._enabled     = true
	self._held        = false
	self._heldStart   = nil
	self._pollState   = Enums.Poll.Idle

	self._comboStep   = 0
	self._comboTimer  = nil

	self._charging    = false
	self._chargeConn  = nil

	self._mashCount   = 0
	self._mashTimer   = nil

	self._iasAction   = nil
	self._iasContext  = nil
	self._iasBindings = {}

	self:_Setup()

	return self
end

function Action:_Fire(state: Enums.State, event: any)
	if not self._enabled then return end
	if not Context.IsActive(self.Config.Contexts) then return end

	local listeners = self._signals[state]
	if not listeners then return end

	for _, entry in listeners do
		if not event.Consumed then
			task.spawn(entry.fire, event)
		end
	end
end

function Action:_PlatformAllowed(): boolean
	local platforms = self.Config.Platforms
	if not platforms or #platforms == 0 then return true end

	local Platform = require(script.Parent.Platform)
	local current  = Platform.Get()

	for _, p in platforms do
		if p == current then return true end
	end

	return false
end

function Action:_SetupIAS()
	local IAS = game:GetService("InputActionService") :: any

	local actionType = "Bool"
	local mode = self.Config.Mode or Enums.Mode.Button

	if mode == Enums.Mode.Axis then
		actionType = "Direction1D"
	end

	local iasAction  = IAS:CreateInputAction(self.Name, Enum.InputActionType[actionType])
	self._iasAction  = iasAction

	local iasContext = IAS:CreateInputContext(self.Name .. "_Context")
	iasContext.Priority = self.Config.Priority or 100
	iasContext.Sink     = self.Config.Sink or false
	self._iasContext    = iasContext

	if self.Config.Bindings then
		for _, binding in self.Config.Bindings do
			local iasBinding = IAS:CreateInputBinding(iasAction, binding)
			table.insert(self._iasBindings, iasBinding)
		end
	end

	iasContext:AddAction(iasAction)
	iasContext:Activate()

	iasAction.StateChanged:Connect(function(newState, _oldState)
		if not self:_PlatformAllowed() then return end

		local source = self.Config.Bindings and self.Config.Bindings[1] or Enum.KeyCode.Unknown

		if newState == Enum.InputActionState.Pressed then
			self:_HandlePressed(source)
		elseif newState == Enum.InputActionState.Released then
			self:_HandleReleased(source)
		elseif newState == Enum.InputActionState.Changed then
			local event = _makeEvent(source, Enums.State.Changed, {
				Progress = iasAction:GetState(),
			})
			self:_Fire(Enums.State.Changed, event)
		end
	end)
end

function Action:_SetupCAS()
	if not self.Config.Bindings then return end

	local bindings = {}
	for _, b in self.Config.Bindings do
		table.insert(bindings, b)
	end

	ContextActionService:BindActionAtPriority(
		self.Name,
		function(_, inputState, inputObject)
			if not self:_PlatformAllowed() then
				return Enum.ContextActionResult.Pass
			end

			local source = inputObject.KeyCode ~= Enum.KeyCode.Unknown
				and inputObject.KeyCode
				or inputObject.UserInputType

			if inputState == Enum.UserInputState.Begin then
				self:_HandlePressed(source)
			elseif inputState == Enum.UserInputState.End then
				self:_HandleReleased(source)
			elseif inputState == Enum.UserInputState.Change then
				local event = _makeEvent(source, Enums.State.Changed, {
					Delta    = inputObject.Delta,
					Position = inputObject.Position,
				})
				self:_Fire(Enums.State.Changed, event)
			end

			return Enum.ContextActionResult.Pass
		end,
		false,
		self.Config.Priority or 100,
		table.unpack(bindings)
	)
end

function Action:_SetupUIS()
	if not self.Config.Bindings then return end

	self._uisConn = UserInputService.InputBegan:Connect(function(input, processed)
		if processed then return end
		if not self:_PlatformAllowed() then return end

		for _, binding in self.Config.Bindings do
			if input.KeyCode == binding or input.UserInputType == binding then
				self:_HandlePressed(binding)
				break
			end
		end
	end)

	self._uisEndConn = UserInputService.InputEnded:Connect(function(input)
		if not self:_PlatformAllowed() then return end

		for _, binding in self.Config.Bindings do
			if input.KeyCode == binding or input.UserInputType == binding then
				self:_HandleReleased(binding)
				break
			end
		end
	end)
end

function Action:_Setup()
	if self._driver == Enums.Driver.IAS then
		self:_SetupIAS()
	elseif self._driver == Enums.Driver.CAS then
		self:_SetupCAS()
	elseif self._driver == Enums.Driver.UIS then
		self:_SetupUIS()
	end
end

function Action:_HandlePressed(source: Enum.KeyCode | Enum.UserInputType)
	self._held      = true
	self._heldStart = os.clock()
	self._pollState = Enums.Poll.Active

	local mode = self.Config.Mode or Enums.Mode.Button

	if mode == Enums.Mode.Button or mode == Enums.Mode.Shortcut then
		local event = _makeEvent(source, Enums.State.Pressed)
		self:_Fire(Enums.State.Pressed, event)
		self:_StartHeldLoop(source)
	elseif mode == Enums.Mode.Hold then
		self:_StartHoldTimer(source)
	elseif mode == Enums.Mode.Charge then
		self:_StartCharge(source)
	elseif mode == Enums.Mode.DoubleTap then
		self:_HandleDoubleTap(source)
	elseif mode == Enums.Mode.Mash then
		self:_HandleMash(source)
	elseif mode == Enums.Mode.Combo then
		self:_HandleComboStep(source)
	elseif mode == Enums.Mode.LongPress then
		self:_StartLongPress(source)
	end
end

function Action:_HandleReleased(source: Enum.KeyCode | Enum.UserInputType)
	self._held      = false
	self._heldStart = nil
	self._pollState = Enums.Poll.Idle

	local mode  = self.Config.Mode or Enums.Mode.Button
	local event = _makeEvent(source, Enums.State.Released)
	self:_Fire(Enums.State.Released, event)

	if mode == Enums.Mode.Hold and self._holdTimer then
		task.cancel(self._holdTimer)
		self._holdTimer = nil
	end

	if mode == Enums.Mode.Charge then
		self:_StopCharge(source)
	end

	if mode == Enums.Mode.LongPress and self._longPressTimer then
		task.cancel(self._longPressTimer)
		self._longPressTimer = nil
		local cancelEvent = _makeEvent(source, Enums.State.Canceled)
		self:_Fire(Enums.State.Canceled, cancelEvent)
	end
end

function Action:_StartHeldLoop(source: Enum.KeyCode | Enum.UserInputType)
	if not self.Config.RepeatInterval then return end

	task.spawn(function()
		while self._held do
			task.wait(self.Config.RepeatInterval)
			if not self._held then break end
			local event = _makeEvent(source, Enums.State.Held, { Held = true })
			self:_Fire(Enums.State.Held, event)
		end
	end)
end

function Action:_StartHoldTimer(source: Enum.KeyCode | Enum.UserInputType)
	local holdTime = self.Config.HoldTime or 0.5
	self._holdTimer = task.delay(holdTime, function()
		if self._held then
			self._holdTimer = nil
			local event = _makeEvent(source, Enums.State.Triggered)
			self:_Fire(Enums.State.Triggered, event)
		end
	end)
end

function Action:_StartCharge(source: Enum.KeyCode | Enum.UserInputType)
	self._charging    = true
	self._chargeStart = os.clock()

	self._chargeConn = RunService.Heartbeat:Connect(function()
		if not self._charging then return end
		local elapsed  = os.clock() - self._chargeStart
		local holdTime = self.Config.HoldTime or 1
		local progress = math.clamp(elapsed / holdTime, 0, 1)
		local event    = _makeEvent(source, Enums.State.Charged, { Progress = progress })
		self:_Fire(Enums.State.Charged, event)
	end)
end

function Action:_StopCharge(source: Enum.KeyCode | Enum.UserInputType)
	if not self._charging then return end
	self._charging = false

	if self._chargeConn then
		self._chargeConn:Disconnect()
		self._chargeConn = nil
	end

	local elapsed  = os.clock() - (self._chargeStart or os.clock())
	local holdTime = self.Config.HoldTime or 1
	local progress = math.clamp(elapsed / holdTime, 0, 1)
	local event    = _makeEvent(source, Enums.State.Triggered, { Progress = progress })
	self:_Fire(Enums.State.Triggered, event)
end

function Action:_HandleDoubleTap(source: Enum.KeyCode | Enum.UserInputType)
	local window = self.Config.Window or 0.3

	if self._doubleTapPending then
		self._doubleTapPending = false
		if self._doubleTapTimer then
			task.cancel(self._doubleTapTimer)
			self._doubleTapTimer = nil
		end
		local event = _makeEvent(source, Enums.State.DoubleTapped)
		self:_Fire(Enums.State.DoubleTapped, event)
	else
		self._doubleTapPending = true
		self._doubleTapTimer   = task.delay(window, function()
			self._doubleTapPending = false
			self._doubleTapTimer   = nil
		end)
	end
end

function Action:_HandleMash(source: Enum.KeyCode | Enum.UserInputType)
	local window    = self.Config.Window or 1
	local threshold = self.Config.MashThreshold or 5

	self._mashCount += 1

	if self._mashTimer then
		task.cancel(self._mashTimer)
	end

	self._mashTimer = task.delay(window, function()
		self._mashCount = 0
		self._mashTimer = nil
	end)

	if self._mashCount >= threshold then
		local count     = self._mashCount
		self._mashCount = 0
		if self._mashTimer then
			task.cancel(self._mashTimer)
			self._mashTimer = nil
		end
		local event = _makeEvent(source, Enums.State.Mashed, { Count = count })
		self:_Fire(Enums.State.Mashed, event)
	end
end

function Action:_HandleComboStep(source: Enum.KeyCode | Enum.UserInputType)
	local sequence = self.Config.Sequence
	if not sequence then return end

	local window   = self.Config.Window or 0.4
	local expected = sequence[self._comboStep + 1]
	local matches  = typeof(expected) == "EnumItem" and source == expected

	if not matches then
		self._comboStep = 0
		if self._comboTimer then
			task.cancel(self._comboTimer)
			self._comboTimer = nil
		end
		local cancelEvent = _makeEvent(source, Enums.State.Canceled)
		self:_Fire(Enums.State.Canceled, cancelEvent)
		return
	end

	self._comboStep += 1

	local stepEvent = _makeEvent(source, Enums.State.Stepped, { Step = self._comboStep })
	self:_Fire(Enums.State.Stepped, stepEvent)

	if self._comboTimer then
		task.cancel(self._comboTimer)
	end

	if self._comboStep >= #sequence then
		self._comboStep  = 0
		self._comboTimer = nil
		local event = _makeEvent(source, Enums.State.Triggered)
		self:_Fire(Enums.State.Triggered, event)
	else
		self._comboTimer = task.delay(window, function()
			self._comboStep  = 0
			self._comboTimer = nil
			local cancelEvent = _makeEvent(source, Enums.State.Canceled)
			self:_Fire(Enums.State.Canceled, cancelEvent)
		end)
	end
end

function Action:_StartLongPress(source: Enum.KeyCode | Enum.UserInputType)
	local holdTime = self.Config.HoldTime or 0.6
	self._longPressTimer = task.delay(holdTime, function()
		if self._held then
			self._longPressTimer = nil
			local event = _makeEvent(source, Enums.State.LongPressed)
			self:_Fire(Enums.State.LongPressed, event)
		end
	end)
end

function Action:Next(state: Enums.State): Connection
	return Connection.new(function(fire)
		local listeners = self._signals[state]
		local entry     = { fire = fire }
		table.insert(listeners, entry)

		return function()
			local i = table.find(listeners, entry)
			if i then table.remove(listeners, i) end
		end
	end)
end

function Action:HoldFor(seconds: number): Connection
	return Connection.new(function(fire)
		local timer        = nil
		local releaseEntry = nil

		local entry = {
			fire = function(event)
				timer = task.delay(seconds, function()
					if self._held then
						fire(event)
					end
				end)
			end,
		}

		releaseEntry = {
			fire = function(_event)
				if timer then
					task.cancel(timer)
					timer = nil
				end
			end,
		}

		table.insert(self._signals[Enums.State.Pressed], entry)
		table.insert(self._signals[Enums.State.Released], releaseEntry)

		return function()
			local i = table.find(self._signals[Enums.State.Pressed], entry)
			if i then table.remove(self._signals[Enums.State.Pressed], i) end

			local j = table.find(self._signals[Enums.State.Released], releaseEntry)
			if j then table.remove(self._signals[Enums.State.Released], j) end

			if timer then
				task.cancel(timer)
				timer = nil
			end
		end
	end)
end

function Action:Poll(): Enums.Poll
	return self._pollState
end

function Action:IsHeld(): boolean
	return self._held
end

function Action:HeldDuration(): number
	if not self._heldStart then return 0 end
	return os.clock() - self._heldStart
end

function Action:Enable()
	self._enabled = true
	local event   = _makeEvent(Enum.KeyCode.Unknown, Enums.State.Enabled)
	self:_Fire(Enums.State.Enabled, event)
end

function Action:Disable()
	self._enabled = false
	local event   = _makeEvent(Enum.KeyCode.Unknown, Enums.State.Disabled)
	self:_Fire(Enums.State.Disabled, event)
end

function Action:Destroy()
	self._enabled = false
	self._held    = false

	if self._driver == Enums.Driver.IAS then
		if self._iasContext then self._iasContext:Deactivate() end
		for _, b in self._iasBindings do b:Destroy() end
		if self._iasAction then self._iasAction:Destroy() end
	elseif self._driver == Enums.Driver.CAS then
		ContextActionService:UnbindAction(self.Name)
	elseif self._driver == Enums.Driver.UIS then
		if self._uisConn    then self._uisConn:Disconnect()    end
		if self._uisEndConn then self._uisEndConn:Disconnect() end
	end

	if self._holdTimer      then task.cancel(self._holdTimer)      end
	if self._comboTimer     then task.cancel(self._comboTimer)     end
	if self._mashTimer      then task.cancel(self._mashTimer)      end
	if self._doubleTapTimer then task.cancel(self._doubleTapTimer) end
	if self._longPressTimer then task.cancel(self._longPressTimer) end
	if self._chargeConn     then self._chargeConn:Disconnect()     end

	table.clear(self._signals)
end

return Action
