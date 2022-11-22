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
  
*/

#include "fltk.cxx"

#define init_lua_fltk_State _init_lua_fltk_State
#include "bind-fltk.cxx"
#undef init_lua_fltk_State



static lua_State * S;

void lua_fltk_widget_callback(Fl_Widget * w, void * udata)
{
  lua_settop(S, 0);
  lua_getref(S, (int) udata);
  lua_pushnumber(S, 2);
  lua_gettable(S, 1);
  lua_pushnumber(S, 1);
  lua_gettable(S, 1);
  lua_call(S, 1, 0);
}

void lua_fltk_fl_callback(void * udata)
{
  lua_settop(S, 0);
  lua_getref(S, (int) udata);
  lua_pushnumber(S, 2);
  lua_gettable(S, 1);
  lua_pushnumber(S, 1);
  lua_gettable(S, 1);
  lua_call(S, 1, 0);
}


int lua_fltk__Fl_Widget__callback(lua_State * __S__)
{
  int nparam = lua_gettop(__S__);
  int __ERROR__ = 0;
	
  Fl_Widget * self;
  self = ( class Fl_Widget * )lua_to_Fl_Widget(__S__, 1, &__ERROR__);
  
  if (__ERROR__)
    return 0;

  if (lua_isnil(__S__, 2))
    ;//self->callback(0); // ??
  else {
    lua_settop(__S__, 2);
    lua_newtable(__S__);

    lua_pushnumber(__S__, 1);
    lua_pushvalue(__S__, 1);
    lua_settable(__S__, 3);

    lua_pushnumber(__S__, 2);
    lua_pushvalue(__S__, 2);
    lua_settable(__S__, 3);

    int ref = lua_ref(__S__, 3);
    S = __S__;
    self->callback(lua_fltk_widget_callback, (void *) ref);
  }

  return 0;
}

int lua_fltk__Fl_Menu_Item__callback(lua_State * __S__)
{
  int nparam = lua_gettop(__S__);
  int __ERROR__ = 0;
	
  Fl_Menu_Item * self;
  self = ( class Fl_Menu_Item * )lua_to_Fl_Menu_Item(__S__, 1, &__ERROR__);
  
  if (__ERROR__)
    return 0;

  if (lua_isnil(__S__, 2))
    ;//self->callback(0); // ??
  else {
    lua_settop(__S__, 2);
    lua_newtable(__S__);

    lua_pushnumber(__S__, 1);
    lua_pushvalue(__S__, 1);
    lua_settable(__S__, 3);

    lua_pushnumber(__S__, 2);
    lua_pushvalue(__S__, 2);
    lua_settable(__S__, 3);

    int ref = lua_ref(__S__, 3);
    S = __S__;
    self->callback((Fl_Callback *) lua_fltk_widget_callback, (void *) ref);
  }

  return 0;
}

int lua_fltk__Fl__add_idle__callback(lua_State * __S__)
{
  int nparam = lua_gettop(__S__);
  int __ERROR__ = 0;
  if (lua_istable(__S__, 1)) { lua_remove(__S__, 1); nparam--; }
  {
    lua_settop(__S__, 2);
    lua_newtable(__S__);

    lua_pushnumber(__S__, 1);
    lua_pushvalue(__S__, 1);
    lua_settable(__S__, 3);

    lua_pushnumber(__S__, 2);
    lua_pushvalue(__S__, 1);
    lua_settable(__S__, 3);

    int ref = lua_ref(__S__, 3);
    S = __S__;
    Fl::add_idle(lua_fltk_fl_callback, (void *) ref);
    lua_pushnumber(__S__, ref);
	return 1;
  }

  return 0;
}

int lua_fltk__Fl__remove_idle__callback(lua_State * __S__)
{
  int nparam = lua_gettop(__S__);
  int __ERROR__ = 0;
  if (lua_istable(__S__, 1)) { lua_remove(__S__, 1); nparam--; }
  {
    int ref = (int) lua_tonumber(__S__, 1);
    Fl::remove_idle(lua_fltk_fl_callback, (void *) ref);
  }
  return 0;
}

int lua_fltk__Fl__has_idle__callback(lua_State * __S__)
{
  int nparam = lua_gettop(__S__);
  int __ERROR__ = 0;
  if (lua_istable(__S__, 1)) { lua_remove(__S__, 1); nparam--; }
  {
    int ref = (int) lua_tonumber(__S__, 1);
    lua_pushnumber(__S__, Fl::has_idle(lua_fltk_fl_callback, (void *) ref));
	return 1;
  }

  return 0;
}


static int generic_event_handler(int ev)
{
  int oldtop = lua_gettop(S);

  lua_getglobal(S, "fltk_event_handler");
  if (!lua_isfunction(S, -1))
    return 1;
	
  lua_pushnumber(S, (double)ev);
  lua_call(S, 1, 0);
  lua_settop(S, oldtop);
  return 0;
}

static int activate_event_handler(lua_State *S)
{
  static int already_active = 0;
  if (!already_active)
  {
    Fl::add_handler(generic_event_handler);
    already_active = 1;
  }
  return 0;
}

static int deactivate_event_handler(lua_State *S)
{
  Fl::remove_handler(generic_event_handler);
  return 0;
}

int init_lua_fltk_State(lua_State * dummy)
{
  S = dummy;

  int BS = !_init_lua_fltk_State(S);

  lua_pushcclosure(S, lua_fltk__Fl_Widget__callback, 0);
  lua_setglobal(S, "fl_callback_widget");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl_Widget, 'callback', fl_callback_widget) \n"
"fl_callback_widget = nil \n");

  lua_pushcclosure(S, lua_fltk__Fl_Menu_Item__callback, 0);
  lua_setglobal(S, "fl_callback_menu");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl_Menu_Item, 'callback', fl_callback_menu) \n"
"fl_callback_menu = nil \n");

  lua_pushcclosure(S, lua_fltk__Fl__add_idle__callback, 0);
  lua_setglobal(S, "fl_callback_add_idle");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl, 'add_idle', fl_callback_add_idle) \n"
"fl_callback_add_idle = nil \n");

  lua_pushcclosure(S, lua_fltk__Fl__remove_idle__callback, 0);
  lua_setglobal(S, "fl_callback_remove_idle");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl, 'remove_idle', fl_callback_remove_idle) \n"
"fl_callback_remove_idle = nil \n");

  lua_pushcclosure(S, lua_fltk__Fl__has_idle__callback, 0);
  lua_setglobal(S, "fl_callback_has_idle");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl, 'has_idle', fl_callback_has_idle) \n"
"fl_callback_has_idle = nil \n");

  lua_pushcclosure(S, activate_event_handler, 0);
  lua_setglobal(S, "fl_start_event_handler");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl, 'start_event_handler', fl_start_event_handler) \n"
"fl_start_event_handler = nil \n");

  lua_pushcclosure(S, deactivate_event_handler, 0);
  lua_setglobal(S, "fl_remove_event_handler");
  luaL_dostring(S, 
"bind_lua_addtovtable(Fl, 'stop_event_handler', fl_remove_event_handler) \n"
"fl_remove_event_handler = nil \n");

  luaL_dostring(S, "bind_lua_addtovtable(Fl, 'set_event_handler', function(handler) fltk_event_handler = handler end)");
  
  return BS? 0 : -1;
}

extern "C" int luaopen_murgaLuaFltk (lua_State* L)
{
	return(init_lua_fltk_State(L));
}
