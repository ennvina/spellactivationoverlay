# SpellActivationOverlay - AI Development Guide

## Project Overview

This is a World of Warcraft Classic addon that recreates Retail's Spell Activation Overlay feature, showing visual alerts for spell procs across multiple WoW expansions (Era/SoD, TBC, Wrath, Cata, MoP).

## Architecture Overview

### Core System Components
- **Main Entry**: `SpellActivationOverlay.lua` - Main addon initialization and event handling
- **Components**: Modular system in `components/` directory with clear separation of concerns
- **Classes**: Per-class implementations in `classes/` with shared common logic
- **Variables**: Dynamic state tracking system in `variables/` for different trigger types
- **Options**: Comprehensive UI settings system in `options/`

### Key Architectural Patterns

**Component System**: Each component is self-contained with a clear module name:
```lua
local AddonName, SAO = ...
local Module = "component_name"
```

**Bucket-Display-Trigger Architecture**: 
- `Bucket`: Container for spell effects with unique spellID
- `Display`: Visual representation (overlays/buttons) with hash-based states  
- `Trigger`: Conditional activation system using bit flags for different event types

**Multi-Expansion Support**: Project flags system (`SAO.ERA`, `SAO.WRATH`, etc.) for expansion-specific features:
```lua
SAO.IsProject(SAO.WRATH_AND_ONWARD) -- Check expansion compatibility
```

## Development Workflows

### Build System
The `_script/package.sh` bash script handles multi-expansion releases:
- Creates optimized builds per expansion (removes unused classes/textures/variables)
- Generates TOC files with correct Interface versions
- Handles special Necrosis integration build
- Universal build includes multiple TOC files for cross-expansion compatibility

**Key Commands**:
```bash
cd _script && ./package.sh  # No parameters = Build packages for all flavors
```

```bash
cd _script && ./package.sh forever # With parameter(s) = Build only packages for these flavors
```

### Adding New Spell Effects
1. **Class Implementation**: Add to appropriate `classes/[class].lua` file
2. **Variable Dependencies**: Check if new `variables/` are needed for trigger conditions
3. **Texture Assets**: Add `.blp` files to `textures/` and update `textures/texname.lua`
4. **Options Integration**: Update `options/classoptions.lua` for UI controls

### Variable System Pattern
Variables in `variables/` follow a strict pattern (see `variables/_template.lua`):
```lua
SAO.Variables.variablename = {
    triggers = { SAO.TRIGGER_AURA }, -- Bit flags for event types
    fetchAndSet = function(self, bucket) end, -- Core logic
    event = { names = {"EVENT_NAME"}, isRequired = true }
}
```

## Project-Specific Conventions

### Hash System
Uses sophisticated hash calculation for spell state tracking:
- `HashData.optionIndex` for settings lookup
- Stack-aware hashing for aura-based effects
- Legacy compatibility for older option formats

### Event Registration
Class files register events dynamically based on available keys:
```lua
-- Any key other than "Intrinsics", "Register", "LoadOptions", "IsDisabled" becomes an event
```

### Localization
Translation system in `components/tr.lua` with gradient text support for UI elements.

### Debugging
Consistent debug module pattern: `SAO:Debug(Module, "message")`
`Module` is the name of the current Lua file without the `.lua` extension and is declared at the beginning of the file.
Use `SAO:Trace()`, `SAO:Warn()`, `SAO:Error()` for different log levels. If a trace can be called too frequently, use `SAO:TraceThrottle()`.

Use `--[[DEV_ONLY]]` for development-only code lines.
Use `--[[BEGIN_DEV_ONLY]]` and `--[[END_DEV_ONLY]]` to wrap development-only code blocks.
Development-only code will be excluded from production builds.
Use these markers to either:
- Test something that isn't meant for production e.g, weird stuff that helps debugging
- Add validation checks useful during development, but isn't expected to fail in production

If a check can fail during production builds, it should *not* be wrapped in development-only markers.

## Integration Points

### WoW API Dependencies
- Heavily uses `CombatLogGetCurrentEventInfo()` for spell tracking
- `UnitAura()` for buff/debuff detection  
- `GetSpellInfo()` for spell data validation
- Project detection via `WOW_PROJECT_ID` constants

### External Libraries
- `LibStub` for library management
- `LibButtonGlow-1.0` for action button highlighting effects

### SavedVariables
Configuration stored in `SpellActivationOverlayDB` with structured options per spell/class.

## Critical Files for Understanding
- `components/project.lua` - Expansion detection and compatibility
- `components/bucket.lua` - Core effect container system
- `components/trigger.lua` - Event-driven activation logic
- `classes/common.lua` - Shared spell effect patterns
- `_script/package.sh` - Build system and asset management

When modifying spell effects, always consider expansion compatibility and ensure proper cleanup in the packaging system.