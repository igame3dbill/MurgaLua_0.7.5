#include "lua.h"
#include "lauxlib.h"

#include <stdlib.h>

#define LUAIOSTRINGLIBNAME "murgaLua"

struct iob {
  int closed;
  char *buf;
  size_t allocated;
  size_t offset;
};

#define INITIALSIZE 256

static int resizeiob(struct iob *ob, size_t newsize)
{
  char *b;
  /* Ancient versions of realloc can't handle a NULL ptr */
  if (ob->allocated == 0) {
    b = (char *) malloc(newsize);
  } else {
    b = (char *) realloc(ob->buf, newsize);
  }
  if (!b) {
    if (ob->buf != NULL) {
      free(ob->buf);
    }
    ob->buf = NULL;
    ob->allocated = 0;
    ob->offset = 0;
    ob->closed = 1;
    return 0;
  }
  ob->buf = b;
  ob->allocated = newsize;
  return 1;
}

static int initializeiob(struct iob *ob)
{
  ob->closed = 0;
  ob->buf = NULL;
  ob->allocated = 0;
  ob->offset = 0;
  return resizeiob(ob, INITIALSIZE);
}

static int appendstr(struct iob *ob, const char *s, size_t n)
{
  if (ob->offset + n >= ob->allocated) {
    /* Well, we need more space.  How about adding half again the current size? */
    size_t newsize = ob->offset + (ob->offset / 2) + n;
    if (!resizeiob(ob, newsize)) {
      return 0;
    }
  }
  memcpy(ob->buf + ob->offset, s, n);
  ob->offset += n;
  return 1;
}

static int newoutput(lua_State *L)
{
  struct iob *ob = (struct iob *)lua_newuserdata(L, sizeof(struct iob));
  if (!ob || !initializeiob(ob)) {
    lua_pushliteral(L, "couldn't initialize stringio buffer");
    lua_error(L);
  }
  luaL_getmetatable(L, LUAIOSTRINGLIBNAME);
  lua_setmetatable(L, -2);
  return 1;
}

static struct iob *getiob(lua_State *L, int findex) {
  struct iob *ob = (struct iob *)luaL_checkudata(L, findex, LUAIOSTRINGLIBNAME);
  if (ob == NULL) {
    luaL_argerror(L, findex, "bad iostring");
  }
  return ob;
}


static void erronclosed(lua_State *L, struct iob *ob) {
  if (ob->closed) {
    luaL_error(L, "iostring closed");
  }
}

static int fio_flush(lua_State *L) {
  struct iob *ob = getiob(L, 1);
  erronclosed(L, ob);
  lua_pushboolean(L, 1);
  return 1;
}

static int f_undef(lua_State *L) {
  lua_pushliteral(L, "operation not implemented on iostrings");
  lua_error(L);
  return 0; /* shut up, lint */
}

static int fio_write(lua_State *L) {
  int top, i;
  struct iob *ob = getiob(L, 1);
  erronclosed(L, ob);
  top = lua_gettop(L);
  for (i = 2; i <= top; i++) {
    size_t len;
    const char *s;
    s = luaL_checklstring(L, i, &len);
    if (!appendstr(ob, s, len)) {
      lua_pushliteral(L, "error appending to iostring");
      lua_error(L);
    }
  }
  lua_pushboolean(L, 1);
  return 1;
}

static int f_close(lua_State *L) {
  struct iob *ob = getiob(L, 1);
  erronclosed(L, ob);
  ob->closed = 1;
  lua_pushboolean(L, 1);
  return 1;
}

static int f_gc(lua_State *L) {
  struct iob *ob = getiob(L, 1);
  if (ob->buf != NULL) {
    free(ob->buf);
    ob->buf = NULL;
  }
  ob->closed = 1;
  ob->allocated = 0;
  ob->offset = 0;
  return 0;
}

static int f_getstring(lua_State *L) {
  struct iob *ob = getiob(L, 1);
  if (ob->buf == NULL) {
    /* shouldn't happen, but. */
    lua_pushliteral(L, "");
    return 1;
  }
  lua_pushlstring(L, ob->buf, ob->offset);
  return 1;
}

static int f_tostring(lua_State *L) {
  struct iob *ob = getiob(L, 1);
  char *closed = "";
  if (ob->closed) {
    closed = "closed ";
  }
  lua_pushfstring(L, "%siostring %d (%d chars, %d allocated)", closed, (int)ob, (int)ob->offset, (int)ob->allocated);
  return 1;
}

static const luaL_reg flib[] = {
  {"flush", fio_flush},
  {"read", f_undef},
  {"lines", f_undef},
  {"seek", f_undef},
  {"write", fio_write},
  {"close", f_close},
  {"getstring", f_getstring},
  {"__gc", f_gc},
  {"__tostring", f_tostring},
  {NULL, NULL}
};

static void createmeta(lua_State *L) {
  luaL_newmetatable(L, LUAIOSTRINGLIBNAME);
  lua_pushliteral(L, "__index");
  lua_pushvalue(L, -2);  /* push metatable */
  lua_rawset(L, -3);  /* metatable.__index = metatable */
  luaL_openlib(L, NULL, flib, 0);
}

static const luaL_reg iostringlib[] = {
  {"newIoString",   newoutput},
  {NULL, NULL}
};

int luaopen_iostring(lua_State *L) {
  createmeta(L);
  luaL_openlib(L, LUAIOSTRINGLIBNAME, iostringlib, 0);
  return 0;
}
