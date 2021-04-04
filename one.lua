--==============================================================================
-- Unite all Lua dependencies into just ONE file            <tonyp@acm.org>
-- This is a completely self-contained version -- no external dependencies
--==============================================================================

--==============================================================================
local m = {}
--==============================================================================

local cc = table.concat

--------------------------------------------------------------------------------

function filename_extension(filename,extension)
  --return filename but with given extension
  if filename == nil then return end
  extension = extension or ''           --assume no extension
  return (filename:gsub('([^%.]+).*','%1'..extension))
end

--------------------------------------------------------------------------------

function filename_default_extension(filename,extension)
  --return filename but with given extension ONLY if no extension is in filename
  if filename == nil then return end
  if filename:match('^[^%.]+$') then    --if no extension in original
    return filename_extension(filename,extension)
  else
    return filename
  end
end

--------------------------------------------------------------------------------

function string:quote(quote)            --return the string embedded in 'quotes'
  if quote == nil then                  --decide default quote when none given
    if self:match("'") then             --if single quote inside string
      quote = '"'                       --use double quotes
    elseif self:match('"') then         --if double quote inside string
      quote = "'"                       --use single quotes
    end
    if self:match('\n') or self:match("'") and self:match('"') then --if multi-line or both single and double quote inside string
      local count = 0
      while self:match('%['..('='):rep(count)..'%[') or
            self:match('%]'..('='):rep(count)..'%]') do
        count = count + 1               --count number of = between square brackets we'll need
      end
      return '['..('='):rep(count+1)..'['..self..']'..('='):rep(count+1)..']'
    end
    quote = quote or "'"                --default if no quote given at all
  end
  return quote .. self .. quote         --return quoted string
end

--------------------------------------------------------------------------------

function string:boxed(lt,h,rt,v,rb,lb)  --print a string inside a box
  lt = lt or '+'                        --left top corner character
  rt = rt or lt or '+'                  --right top corner character
  h = h or '-'                          --horizontal line character
  v = v or '|'                          --vertical line character
  lb = lb or lt or '+'                  --left top corner character
  rb = rb or rt or '+'                  --right top corner character

  local indent, self = self:match('(%s*)(.+)') --separate possible leading blanks

  local maxlen = 0                      --maximum length
  for line in self:lines() do
    line = line:expandtabs()
    if #line > maxlen then maxlen = #line end
  end

  local ans = {}
  for line in self:lines() do
    line = line:expandtabs()
    ans[ #ans+1 ] = v
    ans[ #ans+1 ] = ' '
    ans[ #ans+1 ] = line
    ans[ #ans+1 ] = (' '):rep(maxlen-#line+1)
    ans[ #ans+1 ] = v
    ans[ #ans+1 ] = '\n'
  end

  return cc( {                                    --return a single string with ...
    indent, lt, h:rep(maxlen+2), rt,'\n',         --top line
    indent, cc(ans),                              --message
    indent, lb, h:rep(maxlen+2), rb,              --bottom line
    })
end

--------------------------------------------------------------------------------
-- Save a text file as Windows, Linux, or Mac
--------------------------------------------------------------------------------

function putfile(filename,lines,eol)
  eol = eol or 'Linux'                  --default platform
  assert(type(filename) == 'string','String expected for 1st arg')
  assert(type(lines) == 'table','Table expected for 2nd arg')
  assert(type(eol) == 'string','String expected for 3rd arg')
  eol = eol:lower()
  local platforms = {
    ['win'    ] = '\013\010',
    ['win32'  ] = '\013\010',
    ['win64'  ] = '\013\010',
    ['windows'] = '\013\010',
    ['mac'    ] = '\013',
    ['linux'  ] = '\010',
  }
  eol = platforms[ eol ]
  if eol == nil then
    error('Unsupported platform')
    return
  end
  io.open(filename,'wb'):write(cc(lines,eol),eol):close()
end

--------------------------------------------------------------------------------
-- Expand tabs to spaces
--------------------------------------------------------------------------------

function string:expandtabs(width)
  if not self:match('\t') then return self end
  width = width or 10
  local ans = {}
  for c in self:gsplit('\t') do
    ans[ #ans+1 ] = c
    ans[ #ans+1 ] = (' '):rep(width - (#c % width))
  end
  ans[ #ans ] = nil --remove the one tab we went too far
  return cc(ans)
end

--------------------------------------------------------------------------------
-- Returns an iterator to return single lines from multiline text
--------------------------------------------------------------------------------

function string:lines()
  if self:sub(-1) ~= '\n' then self = self .. '\n' end
  return self:gmatch('(.-)\n')          --return self:gsplit('\n')
end

--------------------------------------------------------------------------------
-- Returns an iterator to split a string on the given delimiter (comma by default)
--------------------------------------------------------------------------------

function string:gsplit(delimiter)
  delimiter = delimiter or ','          --default delimiter is comma
  if self:sub(-1) ~= delimiter then self = self .. delimiter end
  return self:gmatch('(.-)'..escape_magic(delimiter))
end

--------------------------------------------------------------------------------
-- Split a string on the given delimiter (comma by default) into a table
--------------------------------------------------------------------------------

function string:split(delimiter,tabled)
  local ans = {}
  if tabled ~= false then tabled = true end       --default is true
  for item in self:gsplit(delimiter) do
    ans[ #ans+1 ] = item
  end
  if unpacked then return unpack(ans) end
  return ans
end

--------------------------------------------------------------------------------

function split_path(path,delimiter)
  delimiter = delimiter or '/'
  if delimiter == '/' then path = path:gsub('\\','/') end
  local t = path:split(delimiter,true)
  return cc(t,delimiter,1,#t-1),t[#t]
end

--------------------------------------------------------------------------------

function escape_magic(s)
  local MAGIC_CHARS_SET = '[%^%$%(%)%%%.%[%]%*%+%-%?]'
  if s == nil then return end
  return (s:gsub(MAGIC_CHARS_SET,'%%%1'))
end

--------------------------------------------------------------------------------
-- Path/File exists
--------------------------------------------------------------------------------

function file_exists(path)
  local f = io.open(path)
  if f == nil then return nil end
  return path
end

--------------------------------------------------------------------------------
-- Return the full path of first matching filename for given require module name
--------------------------------------------------------------------------------

function modname_to_filename(modname)
  modname = modname:gsub('%.','/')
  for path in package.path:gsplit(';') do
    path = path:gsub('%?',modname)
               :gsub('\\','/')
    if file_exists(path) then return path end
  end
end

--==============================================================================

local used = {}                         --keep track of already used modules
local outfile = { line = 0 }            --keep generated output

local LUA_INIT = os.getenv 'LUA_INIT'
if LUA_INIT ~= nil and LUA_INIT:sub(1,1) == '@' then
  LUA_INIT = LUA_INIT:sub(2)
end

--------------------------------------------------------------------------------

local
function p(...)
  local t = {}
  for i,item in ipairs {...} do
    t[i] = tostring(item)
  end
  outfile.line = outfile.line + 1
  outfile[outfile.line] = cc(t,'')
end

--------------------------------------------------------------------------------

local
function print_with_no_comments(line)
  local COMMENT1 = '^%s*%-%-[^%[%]]'
  local COMMENT2 = '^%s*%-%-%s*$'

  if not line:match(COMMENT1) and
     not line:match(COMMENT2) --[[and
     not line:match('^%s*$')]] then
    p(line)
  end
end

--------------------------------------------------------------------------------

local
function parse(filename,no_lua_init,indent)
  local MATCH = [[require%s*%(?(['"]%S+['"])%)?]]
  indent = indent or 0
  no_lua_init = no_lua_init or false

  local
  function do_require(line)
    if line:match '^%s*%-%-[^%[%]]' then return end --ignore sinle comment lines
    local modname = line:match(MATCH)
    if modname then
      modname = modname:sub(2,-2)                   --remove quotes
      local filename = modname_to_filename(modname) --get modname as filename
      if filename then
        if not used[ filename ] then
          p('--[[\n',('Module '..modname:quote()):boxed(),'\n--]]')
          used[ filename ] = true       --mark this filename as processed
          p((' '):rep(indent),'function ',modname:match('([^%.]+)$'),'_require()')
          parse(filename,no_lua_init,indent+2)
          p((' '):rep(indent),'end\n')
        end
        line = line:gsub(MATCH,modname:match('([^%.]+)$')..'_require()')
        print_with_no_comments((' '):rep(indent)..line)
      end
    else
      print_with_no_comments((' '):rep(indent)..line)
    end
  end

  if not no_lua_init and LUA_INIT ~= nil then
    local s = 'require "' .. LUA_INIT:match('([^/\\]+)%.lua$') .. '"'
    LUA_INIT = nil
    do_require(s)
  end

  local check_shebang = true
  for line in io.lines(filename) do
    if check_shebang then
      check_shebang = false
      if line:match '^%s*#' then goto continue end
    end
    do_require(line)
    ::continue::
  end
end

--------------------------------------------------------------------------------

function m.unite(filename,tabled,no_lua_init)
  tabled = tabled or false
  no_lua_init = no_lua_init or false
  parse(filename_default_extension(filename,'.lua'),no_lua_init)  --do the parsing
  if tabled then return outfile end
  return cc(outfile,'\n')
end

--==============================================================================
return m
--==============================================================================
