<div align="center">

<br />
<br />

# MaterialPaint

<img src="https://img.shields.io/badge/MaterialPaint-v0.1.0-6C3EF4?style=for-the-badge&logoColor=white" alt="version" />
<img src="https://img.shields.io/badge/Luau-Roblox-00A2FF?style=for-the-badge&logoColor=white" alt="luau" />
<img src="https://img.shields.io/badge/License-MIT-22c55e?style=for-the-badge" alt="license" />
<img src="https://img.shields.io/badge/Status-In%20Development-f59e0b?style=for-the-badge" alt="status" />
<img src="https://img.shields.io/badge/Plinko%20Labs-Built%20By-e11d48?style=for-the-badge" alt="plinko labs" />

---

**A full-stack input library for Roblox. IAS-first, Promise-based, and cross-platform -- part of the [Material Develop](https://github.com/mkl48/Material-Develop) suite by Plinko Labs.**

</div>

---

## Overview

Input on Roblox is a mess. You end up with `InputBegan` walls, scattered booleans, no priority system, and zero structure once your game gets complex. MaterialPaint fixes that.

You define named actions, get a handle back, and interact entirely through a chainable Promise-based API. The InputActionService does the heavy lifting under the hood -- you never touch it directly.

```lua
local MP = require(game.ReplicatedStorage.Packages.MaterialPaint)
local Enums = MP.Enums

local Jump = MP.Define("Jump", {
    Bindings = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
    Contexts = { "Gameplay" },
})

local KB = Jump:Next(Enums.State.Pressed):Then(function(event)
    event:Consume()
    character:Jump()
end)

MP.PushContext("Gameplay")
```

---

## Features

- **IAS-first** -- real `InputAction`, `InputContext`, and `InputBinding` instances under the hood, with CAS and UIS available via a `Driver` override
- **Promise-based** -- `:Next()` returns a chainable connection; `:Once()` for one-shots, `:Destroy()` to clean up
- **Context stack** -- push and pop named contexts; actions only fire when their context is active
- **Cross-platform** -- per-action platform filters, reactive `Platform.Get()`, `IsConsole()`, `IsMobile()`, `IsComputer()`
- **Action modes** -- Button, Axis, Combo, Hold, Charge, DoubleTap, Mash, LongPress, Gesture, Shortcut
- **Full enums** -- `Enums.State`, `Enums.Mode`, `Enums.Platform`, `Enums.Poll`, `Enums.Driver`
- **Fork and Merge** -- clone actions with overrides, merge multiple actions into one stream
- **Flat API** -- no sub-namespaces, everything lives on `MaterialPaint` directly

---

## Installation

### Wally (recommended)

Add to your `wally.toml`:

```toml
[dependencies]
MaterialPaint = "Ker/MaterialPaint@0.1.0"
```

Then run:

```sh
wally install
```

### Manual

Copy the `MaterialPaint` ModuleScript into `ReplicatedStorage`. MaterialPaint is a **client-only** library -- never require it from a server Script.

---

## Quick Start

```lua
local MP = require(game.ReplicatedStorage.Packages.MaterialPaint)
local Enums = MP.Enums

local Jump = MP.Define("Jump", {
    Bindings = { Enum.KeyCode.Space, Enum.KeyCode.ButtonA },
    Contexts = { "Gameplay" },
})

local Dash = MP.Define("Dash", {
    Contexts  = { "Gameplay" },
    Mode      = Enums.Mode.Combo,
    Sequence  = { Enum.KeyCode.W, Enum.KeyCode.W },
    Window    = 0.3,
})

local Look = MP.Define("Look", {
    Bindings = { Enum.UserInputType.MouseMovement },
    Contexts = { "Gameplay" },
    Mode     = Enums.Mode.Axis,
})

Jump:Next(Enums.State.Pressed):Then(function(event)
    event:Consume()
    character:Jump()
end)

Dash:Next(Enums.State.Triggered):Then(function()
    character:Dash()
end)

Look:Next(Enums.State.Moved):Then(function(event)
    camera:ApplyDelta(event.Delta)
end)

MP.PushContext("Gameplay")
```

---

## API

### MaterialPaint

| Function | Description |
| -- | -- |
| `Define(name, config)` | Register an action, returns a handle |
| `Fetch(name)` | Retrieve a handle by name, returns nil if not found |
| `Fork(name, newName, overrides?)` | Clone an action with optional config overrides |
| `Merge(...)` | Combine multiple action handles into one stream |
| `Poll(name)` | Get the current `Enums.Poll` state of an action |
| `Remove(name)` | Destroy and unregister an action |
| `Clear()` | Destroy and unregister all actions |
| `GetByTag(tag)` | Get all handles with a matching tag |
| `PushContext(name, options?)` | Push a context onto the stack |
| `PopContext(name?)` | Pop a context by name, or pop the top |
| `PeekContext()` | Return the top context name |
| `HasContext(name)` | Check if a context is currently active |
| `ContextStack()` | Return the full context stack |
| `ClearContext()` | Pop all contexts |
| `SnapshotContext()` | Save the current context stack |
| `RestoreContext(snapshot)` | Restore a saved context stack |
| `OnContextPush(name, cb)` | Fire a callback when a context is pushed |
| `OnContextPop(name, cb)` | Fire a callback when a context is popped |
| `OnContextChanged(cb)` | Fire a callback whenever the stack changes |

### Action Handle

| Method | Description |
| -- | -- |
| `:Next(state)` | Returns a `Connection` that fires on the given state |
| `:HoldFor(seconds)` | Returns a `Connection` that resolves after being held |
| `:Poll()` | Returns the current `Enums.Poll` state |
| `:IsHeld()` | Returns true if the action is currently held |
| `:HeldDuration()` | Returns how long the action has been held in seconds |
| `:Enable()` | Re-enable a disabled action |
| `:Disable()` | Suppress an action without unregistering it |
| `:Destroy()` | Teardown the action and all its listeners |

### Connection

| Method | Description |
| -- | -- |
| `:Then(cb)` | Chain a callback, returns self |
| `:Catch(cb)` | Handle errors, returns self |
| `:Once()` | Self-disconnect after first fire, returns self |
| `:Await()` | Yield until resolved |
| `:Destroy()` | Disconnect immediately |

```lua
-- persistent
local KB = Jump:Next(Enums.State.Pressed):Then(function(event)
    character:Jump()
end)

-- one-shot
Jump:Next(Enums.State.Pressed):Then(function(event)
    character:Jump()
end):Once()

-- stored and destroyed later
KB:Destroy()
```

### Platform

| Method | Description |
| -- | -- |
| `MP.Platform.Get()` | Returns the current `Enums.Platform` value |
| `MP.Platform.IsConsole()` | Returns true on console |
| `MP.Platform.IsMobile()` | Returns true on mobile |
| `MP.Platform.IsComputer()` | Returns true on PC |
| `MP.Platform.OnChanged(cb)` | Fires on platform switch, returns a disconnect |

### Enums

```lua
MP.Enums.State    -- Pressed, Released, Held, Changed, Triggered, Canceled,
                  -- Charged, Stepped, Moved, DoubleTapped, LongPressed,
                  -- Mashed, Conflicted, Enabled, Disabled

MP.Enums.Mode     -- Button, Axis, Combo, Shortcut, Hold, Charge,
                  -- DoubleTap, Mash, LongPress, Gesture

MP.Enums.Platform -- Console, Mobile, Computer

MP.Enums.Poll     -- Idle, Active, Held

MP.Enums.Driver   -- IAS, CAS, UIS
```

---

## Patterns

### Charge Attack

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
MP.PushContext("Gameplay")

openMenu()
MP.PushContext("Menu")

closeMenu()
MP.PopContext("Menu")
```

### Platform Adaptive Bindings

```lua
local Sprint = MP.Define("Sprint", {
    Contexts = { "Gameplay" },
    Bindings = {
        { KeyCode = Enum.KeyCode.LeftShift, Platforms = { "Computer" } },
        { KeyCode = Enum.KeyCode.ButtonL3,  Platforms = { "Console"  } },
    },
})

MP.Platform.OnChanged(function(new)
    if new == MP.Enums.Platform.Mobile then
        -- show touch layout
    end
end)
```

### Fork

```lua
local VehicleJump = MP.Fork("Jump", "VehicleJump", {
    Contexts = { "Vehicle" },
})
```

### Merge

```lua
local AnyAttack = MP.Merge(LightAttack, HeavyAttack)

AnyAttack:Next(Enums.State.Pressed):Then(function(event)
    print("attack from:", event.Source)
end)
```

---

## ActionConfig

| Field | Type | Default | Description |
| -- | -- | -- | -- |
| `Bindings` | `{ KeyCode \| UserInputType }` | required | Input sources |
| `Contexts` | `{ string }?` | nil | Active contexts, omit to always fire |
| `Driver` | `Enums.Driver?` | IAS | Backend driver |
| `Mode` | `Enums.Mode?` | Button | Action mode |
| `Sequence` | `{ KeyCode \| UserInputType }?` | nil | Combo steps |
| `Window` | `number?` | 0.4 | Combo timing window in seconds |
| `HoldTime` | `number?` | 0.5 | Seconds for Hold, LongPress, and Charge modes |
| `MashThreshold` | `number?` | 5 | Press count threshold for Mash mode |
| `Deadzone` | `number?` | 0.0 | Axis deadzone magnitude |
| `RepeatInterval` | `number?` | nil | Held re-fire interval in seconds |
| `Priority` | `number?` | 100 | IAS/CAS context priority |
| `Platforms` | `{ Enums.Platform }?` | nil | Platform filter |
| `Tags` | `{ string }?` | nil | Tag grouping for GetByTag |

---

## License

MIT -- built by [Plinko Labs](https://github.com/mkl48)
