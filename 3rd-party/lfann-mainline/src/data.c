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

static void priv_push_data(lua_State* L, struct fann_train_data* ptr)
{
	if(ptr)
	{
		Object* obj = lua_newuserdata(L, sizeof(Object));
		obj->pointer = ptr;
	
		luaL_getmetatable(L, "lfannDaTa");
		lua_setmetatable(L, -2);
	}
	else
		lua_pushnil(L);
}

static int lfann_data_read_from_file(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TSTRING);
	struct fann_train_data* ptr = fann_read_train_from_file(lua_tostring(L, 1));
	priv_push_data(L, ptr);
	
	return 1;
}

static int lfann_data_merge(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	struct fann_train_data* ptr = fann_merge_train_data(obj1->pointer, obj2->pointer);
	priv_push_data(L, ptr);
	
	return 1;
}

static int lfann_data_duplicate(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	struct fann_train_data* ptr = fann_duplicate_train_data(obj->pointer);
	priv_push_data(L, ptr);
	
	return 1;
}

static int lfann_data_subset(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	struct fann_train_data* ptr = fann_subset_train_data(obj->pointer,
		lua_tointeger(L, 2), lua_tointeger(L, 3));
	priv_push_data(L, ptr);
	
	return 1;
}

static int lfann_data_tostring(lua_State* L)
{
	Object* obj = lua_touserdata(L, 1);

	char name[41];
	snprintf(name, 40, "Training Data: %p", obj->pointer);
	lua_pushstring(L, name);

	return 1;
}

static int lfann_data_gc(lua_State* L)
{
	#ifdef IDEBUG
	fprintf(stderr, "Garbage collecting a Training Data\n");
	#endif
	
	Object* obj = lua_touserdata(L, 1);
	fann_destroy_train(obj->pointer);
	
	return 0;
}

static int lfann_data_shuffle(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	fann_shuffle_train_data(obj->pointer);
	
	return 0;
}

static int lfann_data_save(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_save_train(obj->pointer, lua_tostring(L, 2));
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_data_save_to_fixed(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_save_train_to_fixed(obj->pointer, lua_tostring(L, 2),
		lua_tointeger(L, 3));
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_data_lenght(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_length_train_data(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_data_num_input(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_num_input_train_data(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_data_num_output(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_num_output_train_data(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

/*
 There's a bug in FANN 2.1beta that makes this unusable. lfann reimplements
 the scaling functions in the file extension.c .
static int lfann_data_scale(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1); 
	fann_scale_train_data(obj->pointer, lua_tonumber(L, 2), lua_tonumber(L, 3)); 
	
	return 0;
}

static int lfann_data_scale_input(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1); 
	fann_scale_input_train_data(obj->pointer, lua_tonumber(L, 2), lua_tonumber(L, 3)); 
	
	return 0;
}

static int lfann_data_scale_output(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1); 
	fann_scale_output_train_data(obj->pointer, lua_tonumber(L, 2), lua_tonumber(L, 3)); 
	
	return 0;
} */
