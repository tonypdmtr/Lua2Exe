--==============================================================================
-- Command line interface related functions                      <tonyp@acm.org>
--==============================================================================

local m = {}

--------------------------------------------------------------------------------
-- Get the Nth option from the command line. Optional value may follow = or :
-- (Non-valued options default to true)
--------------------------------------------------------------------------------

function m.get_option(n)
  local k,v
  for _,arg in ipairs(arg) do
    if arg:sub(1,1) == '-' then
      n = n - 1
      if n == 0 then
        k,v = arg:match '^%-%-?(%S-)[=:](.*)'
        if k == nil then
          k = arg:match '^%-%-?(%S+)'
          v = true
        end
        return k,v
      end
    end
  end
end

--------------------------------------------------------------------------------
-- Get all options as a key/value table.
--------------------------------------------------------------------------------

function m.get_all_options()
  local ans = {}
  local k,v
  local i = 0
  repeat
    i = i + 1
    k,v = m.get_option(i)
    if k ~= nil then ans[k] = v end
  until k == nil
  return ans
end

--------------------------------------------------------------------------------
-- Get the Nth non-option argument from the command line
--------------------------------------------------------------------------------

function m.get_argument(n)
  for _,arg in ipairs(arg) do
    if arg:sub(1,1) ~= '-' then
      n = n - 1
      if n == 0 then return arg end
    end
  end
end

--==============================================================================
return m
--==============================================================================
