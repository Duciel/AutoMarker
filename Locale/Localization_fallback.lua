-- Loaded after every locale file: unsupported client locales and missing
-- translations fall back to the English key, so a missing entry never errors.
AutoMarkerLocale = AutoMarkerLocale or {}
setmetatable(AutoMarkerLocale, { __index = function(t, k) return k end })
