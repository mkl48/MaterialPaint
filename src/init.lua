local Enums    = require(script.Enums)
local Platform = require(script.Platform)
local Context  = require(script.Context)
local Registry = require(script.Registry)
local Types    = require(script.Types)

local MaterialPaint = {}

MaterialPaint.Enums    = Enums
MaterialPaint.Platform = Platform

function MaterialPaint.Define(name: string, config: Types.ActionConfig): Types.ActionHandle
	return Registry.Define(name, config)
end

function MaterialPaint.Fetch(name: string): Types.ActionHandle?
	return Registry.Fetch(name)
end

function MaterialPaint.Fork(name: string, newName: string, overrides: Types.ActionConfig?): Types.ActionHandle
	return Registry.Fork(name, newName, overrides)
end

function MaterialPaint.Merge(...: Types.ActionHandle): Types.MergedHandle
	return Registry.Merge(...)
end

function MaterialPaint.Poll(name: string): Types.PollState
	local action = Registry.Fetch(name)
	assert(action, "[MaterialPaint] Poll: action '" .. name .. "' does not exist")
	return action:Poll()
end

function MaterialPaint.Remove(name: string)
	Registry.Remove(name)
end

function MaterialPaint.Clear()
	Registry.Clear()
end

function MaterialPaint.GetByTag(tag: string): { Types.ActionHandle }
	return Registry.GetByTag(tag)
end

function MaterialPaint.PushContext(name: string, options: Types.ContextOptions?)
	Context.Push(name, options)
end

function MaterialPaint.PopContext(name: string?)
	Context.Pop(name)
end

function MaterialPaint.PeekContext(): string?
	return Context.Peek()
end

function MaterialPaint.HasContext(name: string): boolean
	return Context.Has(name)
end

function MaterialPaint.ContextStack(): { string }
	return Context.Stack()
end

function MaterialPaint.ClearContext()
	Context.Clear()
end

function MaterialPaint.SnapshotContext(): { Types.ContextEntry }
	return Context.Snapshot()
end

function MaterialPaint.RestoreContext(snapshot: { Types.ContextEntry })
	Context.Restore(snapshot)
end

function MaterialPaint.OnContextPush(name: string, cb: (string) -> ()): () -> ()
	return Context.OnPush(name, cb)
end

function MaterialPaint.OnContextPop(name: string, cb: (string) -> ()): () -> ()
	return Context.OnPop(name, cb)
end

function MaterialPaint.OnContextChanged(cb: ({ string }) -> ()): () -> ()
	return Context.OnChanged(cb)
end

return MaterialPaint