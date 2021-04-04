--==============================================================================
-- Compiles Lua source and converts it to stand-alone executable via TinyC
-- Written on 2017.02.28 by Tony Papadimitriou <tonyp@acm.org>
--==============================================================================

local cli = require 'cli'
local option = cli.get_all_options()
local cc = table.concat

local filename = cli.get_argument(1)

if filename == nil then
  print('Usage: '..arg[0]..' filename')
  print [[  Converts Lua source program to C for Lua stand-alone executable.

  Options:
    -E ignore environment variables

  Automatically compiles it with TinyC and compresses with UPX]]
  return
end

--------------------------------------------------------------------------------
local one = require 'one'
filename = filename_extension(filename,'')
local file = one.unite(filename_default_extension(filename,'.lua'),false,option.E)
--------------------------------------------------------------------------------

local
function basename(filename)
  return (filename:match '[^/\\]+$')
end

--------------------------------------------------------------------------------

local
function run(cmd,debug)
  if debug == nil then debug = true else debug = false end
  assert(type(cmd) == 'string','cmd should be the string of the command to run')
  if debug then print('Running...',cmd) end
  local f = io.popen(cmd)
  local ans = f:read('*a')
  f:close()
  return ans
end

--------------------------------------------------------------------------------

local outfile = {}

outfile[#outfile+1] = [[
/*
Template for creating stand-alone EXE files from Lua source
Compile with something like: tcc -B/tcc -I/progs/lua/compiler your_prog.c
*/

#define l_getlocaledecpoint() '.'

#define SQLITE_DEFAULT_FOREIGN_KEYS 1
#define SQLITE_ENABLE_RTREE 1
#define SQLITE_SOUNDEX 1
#define SQLITE_ENABLE_STAT4 1
#define SQLITE_ENABLE_UPDATE_DELETE_LIMIT 1
#define SQLITE_ENABLE_FTS4 1
#define SQLITE_ENABLE_FTS5 1
#define SQLITE_DEFAULT_RECURSIVE_TRIGGERS 1

/* core -- used by all */
#include <lapi.c>
#include <lcode.c>
#include <lctype.c>
#include <ldebug.c>
#include <ldo.c>
#include <ldump.c>
#include <lfunc.c>
#include <lgc.c>
#include <llex.c>
#include <lmem.c>
#include <lobject.c>
#include <lopcodes.c>
#include <lparser.c>
#include <lstate.c>
#include <lstring.c>
#include <ltable.c>
#include <ltm.c>
#include <lundump.c>
#include <lvm.c>
#include <lzio.c>

/* auxiliary library -- used by all */
#include <lauxlib.c>

/* standard library  -- not used by luac */
#include <lbaselib.c>
#if defined(LUA_COMPAT_BITLIB)
#include <lbitlib.c>
#endif
#include <lcorolib.c>
#include <ldblib.c>
#include <liolib.c>
#include <lmathlib.c>
#include <loadlib.c>
#include <loslib.c>
#include <lstrlib.c>
#include <ltablib.c>
#include <lutf8lib.c>
#include <linit.c>

/*
** Create the 'arg' table, which stores all arguments from the
** command line ('argv'). It should be aligned so that, at index 0,
** it has 'argv[script]', which is the script name. The arguments
** to the script (everything after 'script') go to positive indices;
** other arguments (before the script name) go to negative indices.
** If there is no script name, assume interpreter's name as base.
*/
static void createargtable (lua_State *L, char **argv, int argc, int script) {
  int i, narg;
  if (script == argc) script = 0;  /* no script name? */
  narg = argc - (script + 1);  /* number of positive indices */
  lua_createtable(L, narg, script + 1);
  for (i = 0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i - script);
  }
  lua_setglobal(L, "arg");
}

/* Define the script we are going to run */

const char my_prog[] = {
]]

file = string.dump(load(file,filename_extension(filename,''),'t'))
local count = 0
local bytes = {}
for c in file:gmatch '.' do
  bytes[#bytes+1] = ('0x%02x'):format(c:byte())
  count = count + 1
  if count > 14 then
    outfile[#outfile+1] = cc(bytes,',')..','
    count = 0
    bytes = {}
  end
end
if count > 0 then outfile[#outfile+1] = cc(bytes,',') end

outfile[#outfile+1] = [[
  };

int
main(int argc, char **argv)
{
  int status, result, i;
  double sum;
  lua_State *L;

  L = luaL_newstate(); /* Create new Lua context */
  luaL_openlibs(L); /* Load Lua libraries */
  createargtable(L, argv, argc, 0);  /* create table 'arg' */

  status = luaL_loadbuffer(L,my_prog,sizeof(my_prog),"]] .. basename(filename_extension(filename,'')) .. [[");

  if (status) {
      /* If failed, error message is at the top of the stack */
      fprintf(stderr, "Loading error: %s\n", lua_tostring(L, -1));
      exit(1);
  }

  status = lua_pcall(L, 0, 0, 0);     /* call the loaded chunk */

  if (status) {
      /* If failed, error message is at the top of the stack */
      fprintf(stderr, "Runtime error: %s\n", lua_tostring(L, -1));
      exit(1);
  }

  lua_close(L);   /* Done with Lua */
  return 0;
}
]]

--------------------------------------------------------------------------------
-- If no 2nd argument is given, assume the same as input but with .c extension
--------------------------------------------------------------------------------

filename = cli.get_argument(2) or basename(filename) --keep only filename without path if not provided
putfile(filename_extension(filename,'.c'),outfile)
run('tcc -B/tcc -I/progs/lua/compiler '..filename_extension(filename,'.c'))
run('upx --ultra-brute '..filename_extension(filename,'.exe'))

--==============================================================================
