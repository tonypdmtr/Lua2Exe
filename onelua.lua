--==============================================================================
-- Unite all Lua dependencies into just ONE file            <tonyp@acm.org>
-- This is a completely self-contained version -- no external dependencies
--==============================================================================

local one = require 'one'
local cli = require 'cli'
local option = cli.get_all_options()

--==============================================================================

local filename = cli.get_argument(1)

if filename == nil then
  print 'Copyright (c) 2021 by Tony Papadimitriou <tonyp@acm.org>\n'
  print('Usage: '.. arg[0]:match('[^\\/]+$') ..' <main_lua_file> [<new_lua_file>]')
  print [[Create a single Lua source by combining all requirements into one file

  Options:
    -E ignore environment variables
]]
  return
end

local outfile = one.unite(filename,true,option.E) -- unite the given file into a table

--------------------------------------------------------------------------------
-- If no 2nd argument is given, print to console, else write to given filename
--------------------------------------------------------------------------------

filename = cli.get_argument(2)

if filename == nil then
  print(cc(outfile,'\n'))
else
  putfile(filename,outfile)
end
