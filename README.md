<div align="center">

<br />
<br />

# Switch

<img src="https://img.shields.io/badge/Switch-v0.1.0-6C3EF4?style=for-the-badge&logoColor=white" alt="version" />
<img src="https://img.shields.io/badge/Luau-Roblox-00A2FF?style=for-the-badge&logoColor=white" alt="luau" />
<img src="https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge" alt="license" />
<img src="https://img.shields.io/badge/Status-In%20Development-f59e0b?style=for-the-badge" alt="status" />
<img src="https://img.shields.io/badge/Plinko%20Labs-Built%20By-e11d48?style=for-the-badge" alt="plinko labs" />

<br />
<br />

**An input library built on the Input Action System -- modular, promise-driven, and cross-platform.**  
**Part of the [Material Develop](https://github.com/mkl48/Material-Develop) suite by Plinko Labs.**

</div>

---

## Table of Contents

- [Why Switch](#why-switch)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
  - [Actions](#actions)
  - [Connections](#connections)
  - [Contexts](#contexts)
  - [Drivers](#drivers)
  - [States](#states)
  - [Modes](#modes)
- [API Reference](#api-reference)
  - [Switch](#switch-1)
  - [Action](#action)
  - [Connection](#connection)
  - [Platform](#platform)
  - [Enums](#enums)
- [Action Modes](#action-modes)
- [Patterns](#patterns)
- [ActionConfig](#actionconfig)
- [Cross-Platform](#cross-platform)
- [Tips & Gotchas](#tips--gotchas)
- [Roadmap](#roadmap)
- [License](#license)

---

## Why Switch

Input on Roblox is fragmented. You're juggling `InputBegan` walls, scattered boolean flags, no priority system, and zero structure once you cross more than a handful of bindings. The new Input Action System fixes the cross-platform problem but its instance-based API is awkward to drive from code.

Switch is the layer on top. You define named actions in code, get back a handle, and interact with it through a chainable Promise-based API. The IAS instance tree is created, parented, and managed for you. You never touch it.

Built around four principles:

- **Named, composable actions** -- no string lookups, no global tables, no remembering what binding fires what
- **Promise-first interaction** -- every input flow is a chainable connection you can store, destroy, and compose
- **Context-aware** -- actions belong to named contexts; push and pop them as game state changes
- **Cross-platform by default** -- IAS handles the keyboard, gamepad, touch, and mouse abstraction natively

---

## Installation

### Wally (recommended)

Add to your `wally.toml`:

```toml
[dependencies]
Switch = "ker/switch@0.1.0"
```

Then run:

```sh
wally install
```

Require from any `LocalScript`:

```lua
local Switch = require(game.ReplicatedStorage.Packages.Switch)
```

### Manual

Drop the `Switch` ModuleScript into `ReplicatedStorage` and require it directly:

```lua
local Switch = require(game.ReplicatedStorage.Switch)
```

> **Note:** Switch is **client-only**. Never require it from a server `Script`.
---

## Quick Start

```lua
local Switch = require(game.ReplicatedStorage.Switch)
local Enums = Switch.Enums

local Jump = Switch.Define("Jump", {
    Bindings = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
    Contexts = { "Gameplay" },
})

Jump:Next(Enums.State.Pressed):Then(function(event)
    event:Consume()
    print("Jumping!")
end)

Switch.PushContext("Gameplay")
```

That's the whole loop. `Define` to register, `:Next` to listen, `:Then` to handle, `PushContext` to activate.

---

## Core Concepts

### Actions

An **Action** is a named gameplay mechanic -- "Jump", "Attack", "Sprint" -- bound to one or more hardware inputs. `Define` registers it and returns a handle. You hold onto that handle. It's the only way to interact with the action.

```lua
local Sprint = Switch.Define("Sprint", {
    Bindings = { Enum.KeyCode.LeftShift, Enum.KeyCode.ButtonL3 },
    Contexts = { "Gameplay" },
})
```

Names are unique. `Define` errors if you reuse one. If you need to retrieve a handle elsewhere, use `Switch.Fetch`.

```lua
local Sprint = Switch.Fetch("Sprint")
```

### Connections

Calling `:Next(state)` on an action returns a **Connection** -- a chainable handle that fires every time the action enters that state. You stack callbacks with `:Then` and `:Catch`, and you can destroy the connection at any time.

```lua
local KB = Jump:Next(Enums.State.Pressed):Then(function(event)
    character:Jump()
end)

-- later, somewhere else
KB:Destroy()
```

Connections are persistent by default. Chain `:Once()` to self-disconnect after the first fire:

```lua
Jump:Next(Enums.State.Pressed):Then(function()
    print("Welcome to the tutorial!")
end):Once()
```

### Contexts

A **Context** is a named string an action belongs to. Push it with `PushContext`, and any action whose `Contexts` array contains that name becomes active. Pop it and they go silent. Stack contexts for layered game state -- "Gameplay" → "Menu" → "Inventory" -- and pop them in reverse to return.

```lua
Switch.PushContext("Gameplay")     -- gameplay actions active
openInventory()
Switch.PushContext("Inventory")    -- inventory + gameplay actions both active
closeInventory()
Switch.PopContext("Inventory")     -- back to gameplay only
```

Actions with no `Contexts` always fire regardless of stack state. Useful for global hotkeys.

### Drivers

Switch speaks three input backends. The default is **IAS** (Input Action System) -- everything you'd want most of the time. CAS and UIS exist as escape hatches.

```lua
Switch.Define("Jump", {
    Bindings = { Enum.KeyCode.Space },
    Driver   = Enums.Driver.IAS,    -- default, can omit
})
```

| Driver | When to use |
| --- | --- |
| `IAS` | Default. Cross-platform, instance-managed, proper priority and sinking |
| `CAS` | Legacy CAS integration, mobile button callbacks, edge cases |
| `UIS` | Bypass everything, raw `InputBegan` / `InputEnded` |

You'll almost always want IAS.

### States

Every action moves between **States**. The full list lives on `Enums.State`. Some are universal (Pressed, Released), some are mode-specific (Charged, Mashed, Stepped). Every state is listenable via `:Next` and queryable via `:Is`.

```lua
Jump:Next(Enums.State.Pressed):Then(function() ... end)
Jump:Next(Enums.State.Released):Then(function() ... end)

if Jump:Is(Enums.State.Held) then
    print("Held for:", Jump:Is(Enums.State.Held):With(), "seconds")
end
```

`:Is(state)` returns `nil` when the state isn't active, or a `StateResult` when it is. Call `:With()` on the result to pull contextual data:

| State | `:With()` returns |
| --- | --- |
| `Held` | Hold duration in seconds |
| `Charged` | Charge progress 0-1 |
| `Mashed` | Press count |
| `Stepped` | Current combo step |
| `Conflicted` | Conflicting action handles |

### Modes

A **Mode** is a behavioral preset on an action. By default actions are `Button` -- they fire `Pressed` and `Released`. Switch to `Combo` and the action only fires `Triggered` when a key sequence completes. Switch to `Charge` and you get continuous `Charged` events with a progress value. See [Action Modes](#action-modes) for the full reference.

---

## API Reference

### Switch

| Function | Description |
| --- | --- |
| `Switch.Define(name, config)` | Register a new action, returns a handle |
| `Switch.Fetch(name)` | Retrieve a handle by name, returns `nil` if missing |
| `Switch.Fork(name, newName, overrides?)` | Clone an action with optional config overrides |
| `Switch.Merge(...)` | Combine multiple action handles into one stream |
| `Switch.Poll(name)` | Get the current `Enums.Poll` state of an action |
| `Switch.Remove(name)` | Destroy and unregister an action |
| `Switch.Clear()` | Destroy and unregister every action |
| `Switch.GetByTag(tag)` | Get all handles with a matching tag |
| `Switch.PushContext(name, options?)` | Push a context onto the stack |
| `Switch.PopContext(name?)` | Pop a context by name, or pop the top |
| `Switch.PeekContext()` | Return the top context name |
| `Switch.HasContext(name)` | Check if a context is currently active |
| `Switch.ContextStack()` | Return the full context stack |
| `Switch.ClearContext()` | Pop every context |
| `Switch.SnapshotContext()` | Capture the current stack |
| `Switch.RestoreContext(snapshot)` | Restore a saved stack |
| `Switch.OnContextPush(name, cb)` | Fire when a context is pushed |
| `Switch.OnContextPop(name, cb)` | Fire when a context is popped |
| `Switch.OnContextChanged(cb)` | Fire whenever the stack changes |

### Action

| Method | Description |
| --- | --- |
| `action:Next(state)` | Returns a `Connection` that fires on the given state |
| `action:HoldFor(seconds)` | Returns a `Connection` that fires after being held |
| `action:Set(state)` | Force-fire a state programmatically through the full pipeline |
| `action:Is(state)` | Returns a `StateResult` if active, `nil` otherwise |
| `action:Poll()` | Returns the current `Enums.Poll` state |
| `action:IsHeld()` | True if currently held |
| `action:HeldDuration()` | Seconds held |
| `action:Enable()` | Re-enable a disabled action |
| `action:Disable()` | Suppress an action without unregistering it |
| `action:Destroy()` | Teardown the action and all its listeners |

### Connection

| Method | Description |
| --- | --- |
| `conn:Then(cb)` | Chain a callback, returns `self` |
| `conn:Catch(cb)` | Handle errors, returns `self` |
| `conn:Once()` | Self-disconnect after first fire |
| `conn:Await()` | Yield until resolved |
| `conn:Destroy()` | Disconnect immediately |

### Platform

| Method | Description |
| --- | --- |
| `Switch.Platform.Get()` | Returns current `Enums.Platform` value |
| `Switch.Platform.IsConsole()` | True if on console |
| `Switch.Platform.IsMobile()` | True if on mobile |
| `Switch.Platform.IsComputer()` | True if on PC |
| `Switch.Platform.OnChanged(cb)` | Fires on platform switch, returns a disconnect |

### Enums

```lua
Switch.Enums.State    -- Pressed, Released, Held, Changed, Triggered, Canceled,
                     -- Charged, Stepped, Moved, DoubleTapped, LongPressed,
                     -- Mashed, Conflicted, Enabled, Disabled

Switch.Enums.Mode     -- Button, Axis, Combo, Shortcut, Hold, Charge,
                     -- DoubleTap, Mash, LongPress, Gesture

Switch.Enums.Platform -- Console, Mobile, Computer

Switch.Enums.Poll     -- Idle, Active, Held

Switch.Enums.Driver   -- IAS, CAS, UIS
```

---

## Action Modes

### Button (default)

The standard mode -- fires `Pressed` and `Released`. Use for jumps, attacks, single-press abilities.

```lua
local Jump = Switch.Define("Jump", {
    Bindings = { Enum.KeyCode.Space },
})

Jump:Next(Enums.State.Pressed):Then(function() ... end)
Jump:Next(Enums.State.Released):Then(function() ... end)
```

### Hold

Fires `Triggered` only after the binding has been held for `HoldTime` seconds. Fires `Canceled` if released early.

```lua
local Block = Switch.Define("Block", {
    Bindings = { Enum.KeyCode.F },
    Mode     = Enums.Mode.Hold,
    HoldTime = 0.5,
})

Block:Next(Enums.State.Triggered):Then(function() ... end)
Block:Next(Enums.State.Canceled):Then(function() ... end)
```

### Charge

Fires `Charged` every Heartbeat with a normalized 0-1 `Progress`. On release fires `Triggered` carrying the final progress.

```lua
local Bow = Switch.Define("Bow", {
    Bindings = { Enum.UserInputType.MouseButton1 },
    Mode     = Enums.Mode.Charge,
    HoldTime = 2,
})

Bow:Next(Enums.State.Charged):Then(function(event)
    UI:SetChargeBar(event.Progress)
end)

Bow:Next(Enums.State.Triggered):Then(function(event)
    Combat:Shoot(event.Progress)
end)
```

### DoubleTap

Fires `DoubleTapped` when two presses occur within `Window` seconds.

```lua
local Dash = Switch.Define("Dash", {
    Bindings = { Enum.KeyCode.E },
    Mode     = Enums.Mode.DoubleTap,
    Window   = 0.3,
})

Dash:Next(Enums.State.DoubleTapped):Then(function() ... end)
```

### Combo

Fires `Stepped` on each valid step in `Sequence`, then `Triggered` when complete. `Canceled` if the wrong key is pressed or the timer expires.

```lua
local Hadoken = Switch.Define("Hadoken", {
    Mode     = Enums.Mode.Combo,
    Sequence = { Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.J },
    Window   = 0.4,
})

Hadoken:Next(Enums.State.Stepped):Then(function(event)
    UI:HighlightStep(event.Step)
end)

Hadoken:Next(Enums.State.Triggered):Then(function() ... end)
```

### Mash

Fires `Mashed` when the binding is pressed `MashThreshold` times within `Window` seconds. Uses a sliding window.

```lua
local Struggle = Switch.Define("Struggle", {
    Bindings      = { Enum.KeyCode.Space },
    Mode          = Enums.Mode.Mash,
    MashThreshold = 10,
    Window        = 2,
})

Struggle:Next(Enums.State.Mashed):Then(function(event)
    print("Broke free in", event.Count, "presses")
end)
```

### LongPress

Mobile-first. Fires `LongPressed` after `HoldTime` seconds. `Canceled` if released early.

```lua
local Pickup = Switch.Define("Pickup", {
    Bindings = { Enum.KeyCode.E },
    Mode     = Enums.Mode.LongPress,
    HoldTime = 0.6,
})

Pickup:Next(Enums.State.LongPressed):Then(function() ... end)
```

### Shortcut

Same as Button but semantically for keyboard shortcuts like Ctrl+S. Used with the `Modifier` field in a `BindingConfig`.

```lua
local Save = Switch.Define("Save", {
    Bindings = {
        { KeyCode = Enum.KeyCode.S, Modifier = Enum.KeyCode.LeftControl },
    },
    Mode = Enums.Mode.Shortcut,
})
```

### Axis

For directional input -- mouse movement, thumbsticks. Fires `Changed` and `Moved` with `Delta` / `Position` data.

```lua
local Look = Switch.Define("Look", {
    Bindings = { Enum.UserInputType.MouseMovement },
    Mode     = Enums.Mode.Axis,
})

Look:Next(Enums.State.Moved):Then(function(event)
    camera:ApplyDelta(event.Delta)
end)
```

---

## Patterns

### Charge Attack with Promise Chain

```lua
Attack:Next(Enums.State.Pressed):Then(function()
    return Attack:HoldFor(0.5)
end):Then(function()
    Combat:HeavyAttack()
end):Catch(function()
    Combat:LightAttack()
end)
```

### Context Switching

```lua
Switch.PushContext("Gameplay")

openMenu()
Switch.PushContext("Menu")

closeMenu()
Switch.PopContext("Menu")
```

### Platform-Adaptive Bindings

```lua
local Sprint = Switch.Define("Sprint", {
    Contexts = { "Gameplay" },
    Bindings = {
        { KeyCode = Enum.KeyCode.LeftShift, Platforms = { "Computer" } },
        { KeyCode = Enum.KeyCode.ButtonL3,  Platforms = { "Console"  } },
    },
})

Switch.Platform.OnChanged(function(new)
    if new == Enums.Platform.Mobile then
        UI:ShowTouchControls()
    end
end)
```

### Fork

Clone an action under a new name with overrides:

```lua
local VehicleJump = Switch.Fork("Jump", "VehicleJump", {
    Contexts = { "Vehicle" },
})
```

### Merge

Combine multiple actions into one stream. Useful for "any attack" or "any direction" listeners:

```lua
local AnyAttack = Switch.Merge(LightAttack, HeavyAttack, Special)

AnyAttack:Next(Enums.State.Pressed):Then(function(event)
    print("attack came from:", event.Source)
end)
```

### Tutorial Gating with `:Once()`

```lua
Switch.PushContext("Tutorial")

local TutorialJump = Switch.Define("TutorialJump", {
    Bindings = { Enum.KeyCode.Space },
    Contexts = { "Tutorial" },
})

TutorialJump:Next(Enums.State.Pressed):Then(function()
    UI:HidePrompt()
    Switch.PopContext("Tutorial")
    Switch.Remove("TutorialJump")
end):Once()
```

### Conditional State Query with `:Is():With()`

```lua
RunService.Heartbeat:Connect(function()
    local charge = Bow:Is(Enums.State.Charged)
    if charge then
        local progress = charge:With()
        UI:SetChargeFill(progress)
    end
end)
```

### Snapshot and Restore

Save your full context state before a cutscene, restore it after:

```lua
local snap = Switch.SnapshotContext()
Switch.ClearContext()
Switch.PushContext("Cutscene")

playCutscene():andThen(function()
    Switch.RestoreContext(snap)
end)
```

### Programmatic Triggers with `:Set()`

Force-fire a state through the full pipeline -- useful for tutorial automation, replay systems, or testing:

```lua
Jump:Set(Enums.State.Pressed)
task.wait(0.1)
Jump:Set(Enums.State.Released)
```

---

## ActionConfig

| Field | Type | Default | Description |
| --- | --- | --- | --- |
| `Bindings` | `{ KeyCode \| UserInputType \| BindingConfig }` | required | Input sources |
| `Contexts` | `{ string }?` | `nil` | Active contexts, omit to always fire |
| `Driver` | `Enums.Driver?` | `IAS` | Backend driver |
| `Mode` | `Enums.Mode?` | `Button` | Action mode |
| `Sequence` | `{ KeyCode \| UserInputType }?` | `nil` | Combo steps |
| `Window` | `number?` | `0.4` | Combo and DoubleTap timing window in seconds |
| `HoldTime` | `number?` | `0.5` | Seconds for Hold, LongPress, and Charge |
| `MashThreshold` | `number?` | `5` | Press count threshold for Mash |
| `Deadzone` | `number?` | `0.0` | Axis deadzone magnitude |
| `RepeatInterval` | `number?` | `nil` | Held re-fire interval |
| `Priority` | `number?` | `100` | IAS / CAS context priority |
| `Sink` | `boolean?` | `false` | Block lower-priority contexts (IAS) |
| `Platforms` | `{ Enums.Platform }?` | `nil` | Platform filter |
| `Tags` | `{ string }?` | `nil` | Tag grouping for `GetByTag` |

### BindingConfig

| Field | Type | Description |
| --- | --- | --- |
| `KeyCode` | `KeyCode \| UserInputType` | Primary input |
| `Modifier` | `Enum.KeyCode?` | Required held modifier (e.g. LeftControl) |
| `Platforms` | `{ Platform }?` | Per-binding platform filter |

---

## Cross-Platform

Switch inherits IAS's cross-platform abstraction. A binding on `Enum.KeyCode.Space` automatically also triggers on `Enum.KeyCode.ButtonA` if both are listed -- no separate listeners required. Filter per-binding with `Platforms` when behavior should differ:

```lua
local Run = Switch.Define("Run", {
    Bindings = {
        { KeyCode = Enum.KeyCode.LeftShift, Platforms = { "Computer" } },
        { KeyCode = Enum.KeyCode.ButtonL3,  Platforms = { "Console"  } },
    },
})
```

Reactively respond to platform switches:

```lua
Switch.Platform.OnChanged(function(new, prev)
    print("switched from", prev, "to", new)
end)
```

---

## Tips & Gotchas

- **Client only.** Switch will error if required from a server `Script`. IAS doesn't exist server-side.
- **Hold your handles.** `Define` returns a handle. Store it. If you lose the reference, use `Fetch(name)`.
- **Names are unique.** Two `Define` calls with the same name will error. Use `Fork` to clone.
- **Context first.** An action with `Contexts = { "Gameplay" }` won't fire until you call `Switch.PushContext("Gameplay")`. This trips everyone up at least once.
- **Driver choice is irreversible.** You can't switch an action's driver after `Define`. Pick at definition time.
- **`:Consume()` blocks the rest of the chain.** If you consume the event in one `:Then`, no later subscribers see it. Useful for priority. Easy to forget.

---

## Roadmap

- Gesture mode implementation (swipe detection)
- Conflict tracking and reporting
- Rebinding API with persistence
- Recording and replay
- Visual debugger overlay
- Touch button layout system

---

## License

MIT -- built by [Plinko Labs](https://github.com/mkl48)

