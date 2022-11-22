/*
 	This file is part of lfann.

	lfann is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	lfann is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with lfann.  If not, see <http://www.gnu.org/licenses/>.

	Copyright (C) 2009 Lucas Hermann Negri
*/

/* C */
#include <string.h>

/* Lua */
#include <lua.h>
#include <lauxlib.h>

/* FANN */
#include <doublefann.h>

#define LIB_NAME "lfann"

typedef struct
{
	void* pointer;
} Object;

typedef struct
{
	lua_State* L;
	int function_ref;
	int ud_ref;
} CallbackInfo;

struct fann_error err_handler;
