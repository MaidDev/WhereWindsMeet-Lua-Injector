-- gm_string_translator_v2_sethook.lua
-- Lua 5.4
--
-- Hooks Text:set_text(self, s, ...) to:
--   - translate text if a translation exists in the dictionary file
--   - optionally collect new strings into the dictionary file (no duplicates)
-- Dictionary file format (one entry per line):
--   ["Original string"] = "Translated string",

if rawget(_G, "GM_STRING_TRANSLATOR_V2_INSTALLED") then
  -- Already installed: avoid installing multiple hooks
  return
end
_G.GM_STRING_TRANSLATOR_V2_INSTALLED = true

-------------------------------------------------
-- Config
-------------------------------------------------
-- File where dictionary entries are stored.
local DICT_PATH = [[C:\temp\Where Winds Meet\Scripts\gm_dict_translation.lua]]

-- Toggle behaviors:
local ENABLE_TRANSLATION     = true   -- use translations from the dictionary
local ENABLE_CAPTURE_NEW     = false   -- if true: append new strings to dictionary; if false: translate only

-- Target source file and function name to hook
local TARGET_SOURCE_SUBSTR   = "hexm/client/ui/base/text.lua"
local TARGET_FUNC_NAME       = "set_text"

-------------------------------------------------
-- Local references (micro-optimizations)
-------------------------------------------------
local debug_getinfo  = debug.getinfo
local debug_getlocal = debug.getlocal
local debug_setlocal = debug.setlocal
local string_find    = string.find
local io_open        = io.open

-------------------------------------------------
-- IO helper
-------------------------------------------------
local function append_to_file(path, line)
  local f = io_open(path, "a")
  if f then
    f:write(line, "\n")
    f:close()
  end
end

-------------------------------------------------
-- String escaping / unescaping
-------------------------------------------------
-- Minimal escaping for safe storage in the dict file
local function escape_lua_string(s)
  return (s
    :gsub("\\", "\\\\")
    :gsub("\n", "\\n")
    :gsub("\r", "\\r")
    :gsub('"', '\\"'))
end

-- Reverse of escape_lua_string (for keys and values read from file)
local function unescape_lua_string(s)
  -- Use a placeholder to avoid interfering replacements on backslashes
  s = s:gsub("\\\\", "\0")   -- temporary placeholder for '\'
  s = s:gsub("\\n", "\n")
  s = s:gsub("\\r", "\r")
  s = s:gsub('\\"', '"')
  s = s:gsub("\0", "\\")    -- restore '\'
  return s
end

-- Normalize quotes inside translation:
-- if the translation contains double quotes (") inside,
-- replace them by single quotes (').
local function normalize_translation_quotes(s)
  if s:find('"', 1, true) then
    s = s:gsub('"', "'")
  end
  return s
end

-------------------------------------------------
-- Dictionaries:
--   TEXT_SEEN:        set of original strings seen in this instance (optional info)
--   WRITTEN_KEYS:     set of already written keys, in ESCAPED form (for file dedup, even across runs)
--   TRANSLATIONS:     map original string -> translated string
-------------------------------------------------
local TEXT_SEEN    = {}
local WRITTEN_KEYS = {}
local TRANSLATIONS = {}

-- Expose for debugging if needed
_G.GM_SET_TEXT_DICT = TEXT_SEEN
_G.GM_TRANSLATION_DICT = TRANSLATIONS

-------------------------------------------------
-- Load existing dictionary entries from file
-------------------------------------------------
do
  local f = io_open(DICT_PATH, "r")
  if f then
    for line in f:lines() do
      -- Match: ["escaped_key"] = "escaped_value",
      local escaped_key, escaped_value = line:match('%["(.-)"%]%s*=%s*"(.-)"')
      if escaped_key then
        -- Mark key as written (prevents duplicates even across runs)
        WRITTEN_KEYS[escaped_key] = true

        -- Recover original key
        local original_key = unescape_lua_string(escaped_key)
        TEXT_SEEN[original_key] = true

        -- If there is a non-empty translation, register it
        if escaped_value and escaped_value ~= "" then
          -- Normalize quotes *inside* the translation: "foo "bar"" -> "foo 'bar'"
          escaped_value = normalize_translation_quotes(escaped_value)
          local translation = unescape_lua_string(escaped_value)
          if translation ~= "" then
            TRANSLATIONS[original_key] = translation
          end
        end
      end
    end
    f:close()
  end
end

-------------------------------------------------
-- Register a new string into the dictionary file
--   - no duplicate lines, even across multiple runs
-------------------------------------------------
local function register_new_string(s)
  if not ENABLE_CAPTURE_NEW then
    return
  end

  if type(s) ~= "string" or s == "" then
    return
  end

  -- Escaped form as it appears in the file
  local escaped = escape_lua_string(s)

  -- If this escaped key has already been written, do nothing.
  -- This guarantees no duplicate lines in the dict file.
  if WRITTEN_KEYS[escaped] then
    return
  end

  WRITTEN_KEYS[escaped] = true
  TEXT_SEEN[s] = true

  -- Write the entry as: ["Original"] = "",
  append_to_file(DICT_PATH, ('["%s"] = "",'):format(escaped))
end

-------------------------------------------------
-- Translate a given text if a translation exists
-------------------------------------------------
local function translate_text(s)
  if not ENABLE_TRANSLATION then
    return s
  end

  local t = TRANSLATIONS[s]
  if t and t ~= "" then
    return t
  end
  return s
end

-------------------------------------------------
-- debug.sethook callback
-------------------------------------------------
local function hook(event)
  if event ~= "call" then
    return
  end

  local info = debug_getinfo(2, "nS")
  if not info then
    return
  end

  local src  = info.source
  local name = info.name

  if not src or not name then
    return
  end

  -- Strip leading '@' from source (Lua script files)
  if src:sub(1, 1) == "@" then
    src = src:sub(2)
  end

  -- Fast checks: only watch the desired file + function name
  if name ~= TARGET_FUNC_NAME then
    return
  end

  if not string_find(src, TARGET_SOURCE_SUBSTR, 1, true) then
    return
  end

  -- At this point we're in Text:set_text(self, s, ...)
  -- Local 1 = self, local 2 = s
  local _, s = debug_getlocal(2, 2)
  if type(s) ~= "string" then
    return
  end

  -- Optionally register string into dictionary file
  register_new_string(s)

  -- Translate if possible
  local new_s = translate_text(s)
  if new_s ~= s then
    debug_setlocal(2, 2, new_s)
  end
end

-------------------------------------------------
-- Install the global hook (for calls only)
-------------------------------------------------
debug.sethook(hook, "c")

return true
