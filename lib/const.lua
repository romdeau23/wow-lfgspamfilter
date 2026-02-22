---@class Addon
local addon, const = select(2, ...), {}
addon.const = const

---@enum FilterMode
const.filterModes = {
    None = 0,
    Default = 1,
    RequireNoVoice = 2,
    RequireScore = 3,
}
