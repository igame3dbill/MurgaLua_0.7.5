/*

  murgaLua
  Copyright (C) 2006-12 John Murga
  
  This program is free software; you can redistribute it and/or
  modify it under the terms of the GNU General Public License
  as published by the Free Software Foundation; either version 2
  of the License, or (at your option) any later version.
  
  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.
  
  You should have received a copy of the GNU General Public License
  along with this program; if not, write to the :
  
    Free Software Foundation, Inc.
    51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

  Extensively modified Lua interpreter
  
  For original code see copyright notice in lua.h
  
*/

extern "C" {
#include <signal.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define lua_c

#include <lua.h>

#include <lauxlib.h>
#include <lualib.h>

#include "../3rd-party/luasocket-2.0.2-MOD/src/luasocket.h"
#include "../3rd-party/luasocket-2.0.2-MOD/src/mime.h"

#include "../3rd-party/md5-1.1.2/src/md5.h"

extern int luaopen_murgaLuaFltk (lua_State *L);
extern int luaopen_alien_core(lua_State *L);
extern int luaopen_alien_struct(lua_State *L);
extern int openMurgaLuaLib(lua_State *L);
extern int luaopen_crypto(lua_State *L);
extern int luaopen_sys(lua_State *L);
extern int luaopen_rings(lua_State *L);
extern int luaopen_lfs(lua_State *L);
extern int luaLZO_open(lua_State* L);
extern int luaopen_iostring(lua_State *L);
extern int luaopen_proAudioRt (lua_State *L);
extern int luaopen_bit(lua_State *L);
extern int luaopen_zlib(lua_State *L);
extern int luaopen_random(lua_State *L);
extern int luaopen_lpeg (lua_State *L);
extern int luaopen_lsqlite3(lua_State *L);
extern int luaopen_lfann(lua_State *L);
extern int luaopen_mongoose(lua_State *L);
extern int luaopen_cjson(lua_State *L);

}

#include "murgaLua.h"

#include "murgaLuaLib-temp.h"
#include "socketLua-temp.h"

static lua_State *globalL = NULL;

static const char *progname = LUA_PROGNAME;

static void lstop (lua_State *L, lua_Debug *ar) {
  (void)ar;  /* unused arg. */
  lua_sethook(L, NULL, 0, 0);
  luaL_error(L, "interrupted!");
}


static void laction (int i) {
  signal(i, SIG_DFL); /* if another SIGINT happens before lstop,
                              terminate process (default action) */
  lua_sethook(globalL, lstop, LUA_MASKCALL | LUA_MASKRET | LUA_MASKCOUNT, 1);
}


static void print_usage (void) {
  fprintf(stderr,
  "usage: %s [options] [script [args]].\n"
  "Available options are:\n"
  "  -M0      Disable all murgaLua functionality (run in pure Lua mode)\n"
  "  -M1      Run in core murgaLua mode (server side features enabled)\n"
  "  -M2      Run in lite murgaLua mode if available (murgaLuaFltk + basic features)\n"
  "  -M3      DEFAULT - Run in FULL murgaLua mode (if available)\n"
  "  -e stat  execute string " LUA_QL("stat") "\n"
  "  -l name  require library " LUA_QL("name") "\n"
  "  -i       enter interactive mode after executing " LUA_QL("script") "\n"
  "  -v       show version information\n"
  "  --       stop handling options\n"
  "  -        execute stdin and stop handling options\n"
  ,
  progname);
  fflush(stderr);
}


static void l_message (const char *pname, const char *msg) {
  if (pname) fprintf(stderr, "%s: ", pname);
  fprintf(stderr, "%s\n", msg);
  fflush(stderr);
}


static int report (lua_State *L, int status) {
  if (status && !lua_isnil(L, -1)) {
    const char *msg = lua_tostring(L, -1);
    if (msg == NULL) msg = "(error object is not a string)";
    l_message(progname, msg);
    lua_pop(L, 1);
  }
  return status;
}


static int traceback (lua_State *L) {
  if (!lua_isstring(L, 1))  /* 'message' not a string? */
    return 1;  /* keep it intact */
  lua_getfield(L, LUA_GLOBALSINDEX, "debug");
  if (!lua_istable(L, -1)) {
    lua_pop(L, 1);
    return 1;
  }
  lua_getfield(L, -1, "traceback");
  if (!lua_isfunction(L, -1)) {
    lua_pop(L, 2);
    return 1;
  }
  lua_pushvalue(L, 1);  /* pass error message */
  lua_pushinteger(L, 2);  /* skip this function and traceback */
  lua_call(L, 2, 1);  /* call debug.traceback */
  return 1;
}


static int docall (lua_State *L, int narg, int clear) {
  int status;
  int base = lua_gettop(L) - narg;  /* function index */
  lua_pushcfunction(L, traceback);  /* push traceback function */
  lua_insert(L, base);  /* put it under chunk and args */
  signal(SIGINT, laction);
  status = lua_pcall(L, narg, (clear ? 0 : LUA_MULTRET), base);
  signal(SIGINT, SIG_DFL);
  lua_remove(L, base);  /* remove traceback function */
  /* force a complete garbage collection in case of errors */
  if (status != 0) lua_gc(L, LUA_GCCOLLECT, 0);
  return status;
}


static void print_version (void) {
  l_message(NULL, LUA_RELEASE "  " LUA_COPYRIGHT);
}


static int getargs (lua_State *L, char **argv, int n) {
  int narg;
  int i;
  int argc = 0;
  while (argv[argc]) argc++;  /* count total number of arguments */
  narg = argc - (n + 1);  /* number of arguments to the script */
  luaL_checkstack(L, narg + 3, "too many arguments to script");
  for (i=n+1; i < argc; i++)
    lua_pushstring(L, argv[i]);
  lua_createtable(L, narg, n + 1);
  for (i=0; i < argc; i++) {
    lua_pushstring(L, argv[i]);
    lua_rawseti(L, -2, i - n);
  }
  return narg;
}


static int dofile (lua_State *L, const char *name) {
  int status = luaL_loadfile(L, name) || docall(L, 0, 1);
  return report(L, status);
}


static int dostring (lua_State *L, const char *s, const char *name) {
  int status = luaL_loadbuffer(L, s, strlen(s), name) || docall(L, 0, 1);
  return report(L, status);
}


static int dolibrary (lua_State *L, const char *name) {
  lua_getglobal(L, "require");
  lua_pushstring(L, name);
  return report(L, docall(L, 1, 1));
}


static const char *get_prompt (lua_State *L, int firstline) {
  const char *p;
  lua_getfield(L, LUA_GLOBALSINDEX, firstline ? "_PROMPT" : "_PROMPT2");
  p = lua_tostring(L, -1);
  if (p == NULL) p = (firstline ? LUA_PROMPT : LUA_PROMPT2);
  lua_pop(L, 1);  /* remove global */
  return p;
}


static int incomplete (lua_State *L, int status) {
  if (status == LUA_ERRSYNTAX) {
    size_t lmsg;
    const char *msg = lua_tolstring(L, -1, &lmsg);
    const char *tp = msg + lmsg - (sizeof(LUA_QL("<eof>")) - 1);
    if (strstr(msg, LUA_QL("<eof>")) == tp) {
      lua_pop(L, 1);
      return 1;
    }
  }
  return 0;  /* else... */
}


static int pushline (lua_State *L, int firstline) {
  char buffer[LUA_MAXINPUT];
  char *b = buffer;
  size_t l;
  const char *prmt = get_prompt(L, firstline);
  if (lua_readline(L, b, prmt) == 0)
    return 0;  /* no input */
  l = strlen(b);
  if (l > 0 && b[l-1] == '\n')  /* line ends with newline? */
    b[l-1] = '\0';  /* remove it */
  if (firstline && b[0] == '=')  /* first line starts with `=' ? */
    lua_pushfstring(L, "return %s", b+1);  /* change it to `return' */
  else
    lua_pushstring(L, b);
  lua_freeline(L, b);
  return 1;
}


static int loadline (lua_State *L) {
  int status;
  lua_settop(L, 0);
  if (!pushline(L, 1))
    return -1;  /* no input */
  for (;;) {  /* repeat until gets a complete line */
    status = luaL_loadbuffer(L, lua_tostring(L, 1), lua_strlen(L, 1), "=stdin");
    if (!incomplete(L, status)) break;  /* cannot try to add lines? */
    if (!pushline(L, 0))  /* no more input? */
      return -1;
    lua_pushliteral(L, "\n");  /* add a new line... */
    lua_insert(L, -2);  /* ...between the two lines */
    lua_concat(L, 3);  /* join them */
  }
  lua_saveline(L, 1);
  lua_remove(L, 1);  /* remove line */
  return status;
}


static void dotty (lua_State *L) {
  int status;
  const char *oldprogname = progname;
  progname = NULL;
  while ((status = loadline(L)) != -1) {
    if (status == 0) status = docall(L, 0, 0);
    report(L, status);
    if (status == 0 && lua_gettop(L) > 0) {  /* any result to print? */
      lua_getglobal(L, "print");
      lua_insert(L, 1);
      if (lua_pcall(L, lua_gettop(L)-1, 0, 0) != 0)
        l_message(progname, lua_pushfstring(L,
                               "error calling " LUA_QL("print") " (%s)",
                               lua_tostring(L, -1)));
    }
  }
  lua_settop(L, 0);  /* clear stack */
  fputs("\n", stdout);
  fflush(stdout);
  progname = oldprogname;
}


static int handle_script (lua_State *L, char **argv, int n) {
  int status;
  const char *fname;
  int narg = getargs(L, argv, n);  /* collect arguments */
  lua_setglobal(L, "arg");
  fname = argv[n];
  if (strcmp(fname, "-") == 0 && strcmp(argv[n-1], "--") != 0) 
    fname = NULL;  /* stdin */
  status = luaL_loadfile(L, fname);
  lua_insert(L, -(narg+1));
  if (status == 0)
    status = docall(L, narg, 0);
  else
    lua_pop(L, narg);      
  return report(L, status);
}


/* check that argument has no extra characters at the end */
#define notail(x)	{if ((x)[2] != '\0') return -1;}


static int collectargs (char **argv, int *pi, int *pv, int *pe, char *murgaLuaLevel) {
  int i;
  for (i = 1; argv[i] != NULL; i++) {
    if (argv[i][0] != '-')  /* not an option? */
        return i;
    switch (argv[i][1]) {  /* option */
      case '-':
        notail(argv[i]);
        return (argv[i+1] != NULL ? i+1 : 0);
      case '\0':
        return i;
      case 'i':
        notail(argv[i]);
        *pi = 1;  /* go through */
      case 'v':
        notail(argv[i]);
        *pv = 1;
        break;
      case 'M':
        if (argv[i][2] != '\0')
        *murgaLuaLevel = argv[i][2];
        break;
      case 'e':
        *pe = 1;  /* go through */
      case 'l':
        if (argv[i][2] == '\0') {
          i++;
          if (argv[i] == NULL) return -1;
        }
        break;
      default: return -1;  /* invalid option */
    }
  }
  return 0;
}


static int runargs (lua_State *L, char **argv, int n) {
  int i;
  for (i = 1; i < n; i++) {
    if (argv[i] == NULL) continue;
    lua_assert(argv[i][0] == '-');
    switch (argv[i][1]) {  /* option */
      case 'e': {
        const char *chunk = argv[i] + 2;
        if (*chunk == '\0') chunk = argv[++i];
        lua_assert(chunk != NULL);
        if (dostring(L, chunk, "=(command line)") != 0)
          return 1;
        break;
      }
      case 'l': {
        const char *filename = argv[i] + 2;
        if (*filename == '\0') filename = argv[++i];
        lua_assert(filename != NULL);
        if (dolibrary(L, filename))
          return 1;  /* stop if file fails */
        break;
      }
      default: break;
    }
  }
  return 0;
}


static int handle_luainit (lua_State *L) {
  const char *init = getenv(LUA_INIT);
  if (init == NULL) return 0;  /* status OK */
  else if (init[0] == '@')
    return dofile(L, init+1);
  else
    return dostring(L, init, "=" LUA_INIT);
}


struct Smain {
  int argc;
  char **argv;
  int status;
};

static int readable (const char *filename) {
  FILE *f = fopen(filename, "r");  /* try to open file */
  if (f == NULL) return 0;  /* open failed */
  fclose(f);
  return 1;
}

static const char *findExe (const char *name)
{
	char filename[256];
    char candidate[2048];
    char *path, *dir;
	
	strcpy(filename, name);

	#ifdef _WIN32
		const char *path_delim = ";";
		const char *path_sep = "\\";
		if (strstr(filename, ".exe") == NULL)
			strcat(filename, ".exe");
	#else
		const char *path_delim = ":";
		const char *path_sep = "/";
	#endif
	
	// printf("Finding '%s'", name);
    path = getenv("PATH");
    if (path != NULL)
	{
        path = strdup(path);
        for (dir = strtok(path, path_delim); dir != NULL; dir = strtok(NULL, path_delim))
		{
            strcpy(candidate, dir);
            strcat(candidate, path_sep);
            strcat(candidate, filename);
            if (readable(candidate))
			{
                // printf("- Executable is '%s' (from PATH).\n", candidate);
				char *new_data = new char[strlen(candidate) + 1];
				strcpy(new_data, candidate);
                return new_data;
            }
        }
        free(path);
    }
	return 0;
}

int setBindTables(lua_State * __S__)
{
  lua_settop(__S__, 0);
	
  /* Create lua_bindtypes table if necessary */
  lua_getglobal(__S__, "lua_bindtypes");
  if (lua_type(__S__, 1) != LUA_TTABLE) { lua_pop(__S__, 1); lua_newtable(__S__); lua_setglobal(__S__, "lua_bindtypes"); }
  lua_settop(__S__, 0);

  luaL_dostring(__S__,
"function bind_lua_buildparents(ti) \n"
"  bind_lua_buildcompattag(ti, ti) \n"
"  local i, v, parent, j \n"
"  for j=1,ti.n,1 do \n"
"    parent = ti[j] \n"
"--    print(parent.name, 'is parent of', ti.name, 'with tag', ti.name) \n"
"    if type(parent)=='table' then \n"
"      local parentvtable = parent.vtable \n"
"      for i, v in pairs(parentvtable) do \n"
"        ti.vtable[i] = v \n"
"      end \n"
"    end \n"
"  end \n"
"end \n"
"  \n"
"function bind_lua_buildcompattag(ti, parent) \n"
"  if not parent or not parent.n then return end \n"
"  local i \n"
"  ti.compattag[ti.vtable] = ti \n"
"  for i=1,parent.n,1 do \n"
"    if parent[i] and parent[i].compattag then \n"
"      parent[i].compattag[ti.vtable] = ti \n"
"      ti.vtable[parent[i].id] = 1 \n"
"      bind_lua_buildcompattag(ti, parent[i]) \n"
"    end \n"
"  end \n"
"end \n"
" \n"
"function bind_lua_addtovtable(vtable, index, value) \n"
"  vtable[index] = value \n"
"  local ti = vtable.bind_lua_typeinfo \n"
"  if not ti or not ti.compattag then \n"
"    return \n"
"  end \n"
"  local tt = ti.compattag \n"
"  local i, v \n"
"  for i, v in pairs(tt) do \n"
"    local vt2 = v.vtable \n"
"    if not vt2[index] then \n"
"      bind_lua_addtovtable(vt2, index, value) \n"
"    end \n"
"  end \n"
"end \n"
);
}

int runEmbedded(lua_State *L, const char *codeBlock, int codeSize, char *blockName)
{
  luaL_loadbuffer (L, codeBlock, codeSize, blockName);
  
  if(lua_pcall (L, 0, 0, 0)!= 0)
  {
    fprintf(stderr, "Error with embedded code (%s) : %s", blockName, lua_tostring(L, -1));
	return 0;
  }
  return 1;
}

extern "C" int enableRingsStable(lua_State *L)
{
  return runEmbedded (L, murgaLuaLib_Stable, sizeof(murgaLuaLib_Stable), "stable");
}

int enableBasicFeatures(lua_State *L)
{
  setBindTables(L);

  luaopen_lfs(L);
  luaLZO_open(L);
  luaopen_sys(L);
  luaopen_iostring(L);
  luaopen_socket_core(L);
  luaopen_mime_core(L); 
  luaopen_alien_core(L);
  luaopen_alien_struct(L);
  luaopen_rings(L);
  
  openMurgaLuaLib(L);

  runEmbedded (L, luaSocketCode_socket, sizeof(luaSocketCode_socket),"socket");
  runEmbedded (L, luaSocketCode_ltn12, sizeof(luaSocketCode_ltn12), "ltn12");
  runEmbedded (L, luaSocketCode_tp, sizeof(luaSocketCode_tp), "tp");
  runEmbedded (L, luaSocketCode_mime, sizeof(luaSocketCode_mime), "mime");
  runEmbedded (L, luaSocketCode_url, sizeof(luaSocketCode_url), "url");
  runEmbedded (L, luaSocketCode_ftp, sizeof(luaSocketCode_ftp), "ftp");
  runEmbedded (L, luaSocketCode_http, sizeof(luaSocketCode_http), "http");
  runEmbedded (L, luaSocketCode_smtp, sizeof(luaSocketCode_smtp), "smtp");

  runEmbedded (L, murgaLuaLib_coxpcall, sizeof(murgaLuaLib_coxpcall), "coxpcall");
  runEmbedded (L, murgaLuaLib_copas, sizeof(murgaLuaLib_copas), "copas");

  runEmbedded (L, murgaLuaLib_logging, sizeof(murgaLuaLib_logging), "logging");
  runEmbedded (L, murgaLuaLib_loggingConsole, sizeof(murgaLuaLib_loggingConsole), "logging.console");
  runEmbedded (L, murgaLuaLib_loggingFile, sizeof(murgaLuaLib_loggingFile), "logging.file");
  runEmbedded (L, murgaLuaLib_loggingSocket, sizeof(murgaLuaLib_loggingSocket), "logging.socket");
  runEmbedded (L, murgaLuaLib_loggingEmail, sizeof(murgaLuaLib_loggingEmail), "logging.email");

  runEmbedded (L, murgaLuaLib_alien, sizeof(murgaLuaLib_alien), "alien");

  runEmbedded (L, murgaLuaLib_lua, sizeof(murgaLuaLib_lua), "murgaLua");
  runEmbedded (L, murgaLuaLib_murgaLuaDebug, sizeof(murgaLuaLib_murgaLuaDebug), "murgaLua.debug");
  runEmbedded (L, murgaLuaLib_murgaLua_serialize, sizeof(murgaLuaLib_murgaLua_serialize), "murgaLua.serialize");

  return 1;
}

int enableLiteFeatures(lua_State *L)
{
  #if defined MURGALUA_LITE || defined MURGALUA_FULL
    luaopen_murgaLuaFltk(L);
    runEmbedded (L, murgaLuaLib_fltk, sizeof(murgaLuaLib_fltk), "murgaLua.fltk");
    luaopen_proAudioRt(L);
    return 1;
  #else
    return 0;
  #endif
}

int enableCoreFeatures(lua_State *L)
{
  #if defined MURGALUA_CORE || defined MURGALUA_FULL
    luaopen_crypto(L);
    luaopen_cjson(L);
    luaopen_mongoose(L);
    luaopen_lfann(L); 
    luaopen_lsqlite3(L);
    luaopen_md5_core(L);
    luaopen_random(L);
    
    luaopen_zlib(L);
    lua_setglobal(L, "zlib");
    
    luaopen_bit(L);
      
    luaopen_lpeg(L);
    
    runEmbedded (L, murgaLuaLib_md5, sizeof(murgaLuaLib_md5), "md5");
    runEmbedded (L, murgaLuaLib_date, sizeof(murgaLuaLib_date), "date");

    runEmbedded (L, murgaLuaLib_re, sizeof(murgaLuaLib_re), "re");
    runEmbedded (L, murgaLuaLib_cosmo_grammer, sizeof(murgaLuaLib_cosmo_grammer), "cosmo.grammer");
    runEmbedded (L, murgaLuaLib_cosmo_fill, sizeof(murgaLuaLib_cosmo_fill), "cosmo.fill");
    runEmbedded (L, murgaLuaLib_cosmo, sizeof(murgaLuaLib_cosmo), "cosmo");
    runEmbedded (L, murgaLuaLib_IniLazy, sizeof(murgaLuaLib_IniLazy), "inilazy");

    return 1;
  #else
    return 0;
  #endif
}

int enableFullFeatures(lua_State *L)
{
  #ifdef MURGALUA_FULL
    enableLiteFeatures(L);
    enableCoreFeatures(L);
    return 1;
  #else
    return 0;
  #endif
}

extern "C" void setMurgaLuaGlobals(lua_State *L, int murgaLuaLevel)
{
  lua_pushcclosure(L, enableCoreFeatures, 0);
  lua_setglobal(L, "_enableMurgaLuaCore");
  lua_pushcclosure(L, enableLiteFeatures, 0);
  lua_setglobal(L, "_enableMurgaLuaLite");
  lua_pushcclosure(L, enableFullFeatures, 0);
  lua_setglobal(L, "_enableMurgaLuaFull");
  lua_pushcclosure(L, enableRingsStable, 0);
  lua_setglobal(L, "_enableRingsStable");
  
  lua_pushstring(L, progname);
  lua_setglobal(L, "murgaLua_ExePath");
  lua_pushstring(L, MURGALUA_NOTICE);
  lua_setglobal(L, "murgaLua_About");
  lua_pushstring(L, MURGALUA_VERSION);
  lua_setglobal(L, "murgaLua_Version");
  
  lua_pushnumber(L, murgaLuaLevel);
  lua_setglobal(L, "murgaLua_Level");
}

static int pmain (lua_State *L) {
  struct Smain *s = (struct Smain *)lua_touserdata(L, 1);
  char **argv = s->argv;
  int script;
  int has_i = 0, has_v = 0, has_e = 0;
  char murgaLuaLevel = '9'; // 9 is reserved for "none"
  globalL = L;
  
  if (argv[0] && argv[0][0]) progname = argv[0];
  
  if (strchr(progname, '/') == NULL && strchr(progname, '\\') == NULL)
  {
    const char *progFromPath = findExe(progname);
	if ( progFromPath != NULL )
	  progname = progFromPath;
  }

  script = collectargs(argv, &has_i, &has_v, &has_e, &murgaLuaLevel);
  if (script < 0) {  /* invalid args? */
    print_usage();
    s->status = 1;
    return 0;
  }
  
  if (has_v)
  {
	fprintf(stderr, MURGALUA_NOTICE);
  	print_version();
  }

  lua_gc(L, LUA_GCSTOP, 0);  /* stop collector during initialization */
  luaL_openlibs(L);  /* open libraries */

  enableBasicFeatures(L);

  switch (murgaLuaLevel)
  {
    case '0' :
      // Do nothing
  	break;

    case '1' :
      enableCoreFeatures(L);
  	  break;
    case '2' :
      enableLiteFeatures(L);
      break;

    default  :
      enableFullFeatures(L);
      break;
  }
  
  setMurgaLuaGlobals(L, murgaLuaLevel-'0'); // Hack, hack, hack :-)

  lua_gc(L, LUA_GCRESTART, 0);
  s->status = handle_luainit(L);
  
  if (s->status != 0) return 0;
  
  s->status = runargs(L, argv, (script > 0) ? script : s->argc);
  if (s->status != 0) return 0;
  if (script)
    s->status = handle_script(L, argv, script);
  if (s->status != 0) return 0;
  if (has_i)
    dotty(L);
  else if (script == 0 && !has_e && !has_v && murgaLuaLevel > '0') {
    dostring (L, "murgaLua.decompileMurgaLua(murgaLua_ExePath)", "");
    if (lua_stdin_is_tty()) {
      fprintf(stderr, MURGALUA_NOTICE);
      print_version();
      dotty(L);
    }
    else dofile(L, NULL);  /* executes stdin as a file */
  }
  return 0;
}

int main (int argc, char **argv)
{
  int status;
  struct Smain s;
  lua_State *L = lua_open();  /* create state */
  if (L == NULL) {
    l_message(argv[0], "cannot create state: not enough memory");
    return EXIT_FAILURE;
  }
  s.argc = argc;
  s.argv = argv;
  status = lua_cpcall(L, &pmain, &s);
  report(L, status);
  lua_close(L);
  return (status || s.status) ? EXIT_FAILURE : EXIT_SUCCESS;
}

