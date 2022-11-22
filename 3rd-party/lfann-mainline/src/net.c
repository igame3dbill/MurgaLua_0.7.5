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

static void priv_push_net(lua_State* L, struct fann* ptr)
{
	if(ptr)
	{
		Object* obj = lua_newuserdata(L, sizeof(Object));
		obj->pointer = ptr;
	
		luaL_getmetatable(L, "lfannNeT");
		lua_setmetatable(L, -2);
		fann_set_error_log((struct fann_error *) ptr, NULL);
	}
	else
		lua_pushnil(L);
}

static void free_info(CallbackInfo* info)
{
    luaL_unref(info->L, LUA_REGISTRYINDEX, info->function_ref);
	luaL_unref(info->L, LUA_REGISTRYINDEX, info->ud_ref);
	free(info);
}

static int priv_callback_handle(struct fann* ann, struct fann_train_data* train,
	unsigned int max_epochs, unsigned int epochs_between_reports, 
	float desired_error, unsigned int epochs)
{
	CallbackInfo* ptr = fann_get_user_data(ann);
	int ret = 0;
	
	if(ptr)
	{
		lua_State* L = ptr->L;
		int top = lua_gettop(L);
		
		lua_rawgeti(L, LUA_REGISTRYINDEX, ptr->function_ref);
		lua_rawgeti(L, LUA_REGISTRYINDEX, ptr->ud_ref);
		
		lua_pushinteger(L, max_epochs);
		lua_pushinteger(L, epochs_between_reports);
		lua_pushnumber(L, desired_error);
		lua_pushinteger(L, epochs);
		
		lua_call(L, 5, 1);
		ret = lua_tointeger(L, -1);
		lua_settop(L, top);
	}
	
	return ret;
}

/* Shared code between network constructors. If anything wrong occours, it
 * thows an error.
 * The returned array is always valid, and need to be released by the caller. */
static void priv_create_array(lua_State* L, int tbl_index, 
	unsigned int* ret_n_layers, unsigned int** ret_arr)
{
	#ifdef IDEBUG
	fprintf(stderr, "Creating a new Neural Network\n");
	#endif

	luaL_checktype(L, tbl_index, LUA_TTABLE);
	size_t n_layers = lua_objlen(L, tbl_index);
	if(n_layers <= 1) luaL_error(L, "Can't create a Neural Network with less than two layers");
	
	/* Allocated the temp array and get the neurons of each layer */
	unsigned int* arr = calloc(n_layers, sizeof(unsigned int));
	if(!arr) luaL_error(L, "Couldn't allocate the array");
	
	int i;
	for(i = 1; i <= n_layers; ++i)
	{
		lua_pushinteger(L, i);
		lua_rawget(L, tbl_index);
		
		if(lua_type(L, -1) == LUA_TNUMBER)
		{
			arr[i - 1] = lua_tonumber(L, -1);
			lua_pop(L, 1);
		}
		else
		{
			free(arr);
			luaL_error(L, "The number of neurons must be a number");
		}
	}
	
	/* Return */
	*ret_n_layers = n_layers;
	*ret_arr = arr;
}

static int lfann_net_create_standard(lua_State* L)
{
	unsigned int n_layers, *arr;
	priv_create_array(L, 1, &n_layers, &arr);
	struct fann* ptr = fann_create_standard_array(n_layers, arr);
	free(arr);
	priv_push_net(L, ptr);
	
	return 1;
}

static int lfann_net_create_sparse(lua_State* L)
{
	unsigned int n_layers, *arr;
	priv_create_array(L, 2, &n_layers, &arr);
	struct fann* ptr = fann_create_sparse_array(lua_tonumber(L, 1), n_layers, arr);
	free(arr);
	priv_push_net(L, ptr);
	
	return 1;
}

static int lfann_net_create_shortcut(lua_State* L)
{
	unsigned int n_layers, *arr;
	priv_create_array(L, 1, &n_layers, &arr);
	struct fann* ptr = fann_create_shortcut_array(n_layers, arr);
	free(arr);
	priv_push_net(L, ptr);
	
	return 1;
}

static int lfann_net_create_from_file(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TSTRING);
	
	struct fann* ptr = fann_create_from_file(lua_tostring(L, 1));
	priv_push_net(L, ptr);
		
	return 1;
}

static int lfann_net_tostring(lua_State* L)
{
	Object* obj = lua_touserdata(L, 1);

	char name[41];
	snprintf(name, 40, "Neural Network: %p", obj->pointer);
	lua_pushstring(L, name);

	return 1;
}

static int lfann_net_gc(lua_State* L)
{
	#ifdef IDEBUG
	fprintf(stderr, "Garbage collecting a Neural Network\n");
	#endif
	
	Object* obj = lua_touserdata(L, 1);
	
	/* Destroy the network */
	fann_destroy(obj->pointer);
	
	/* Release the callback if present */
	CallbackInfo* info  = fann_get_user_data(obj->pointer);
	if(info) free_info(info);
	
	return 1;
}

static int lfann_net_print_connections(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	fann_print_connections(obj->pointer);
	
	return 0;
}

static int lfann_net_train_on_file(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	luaL_checktype(L, 5, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_train_on_file(obj->pointer, lua_tostring(L, 2), lua_tointeger(L, 3),
		lua_tointeger(L, 4), lua_tonumber(L, 5));
		
	return 0;
}

static int lfann_net_train_on_data(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	luaL_checktype(L, 5, LUA_TNUMBER);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	fann_train_on_data(obj1->pointer, obj2->pointer, lua_tointeger(L, 3),
		lua_tointeger(L, 4), lua_tonumber(L, 5));
		
	return 0;
}

static int lfann_net_train_epoch(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	float res = fann_train_epoch(obj1->pointer, obj2->pointer);
	lua_pushnumber(L, res);
		
	return 1;
}

static int lfann_net_save(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	
	Object* obj = lua_touserdata(L, 1);
	int res = fann_save(obj->pointer, lua_tostring(L, 2));
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_save_to_fixed(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	
	Object* obj = lua_touserdata(L, 1);
	int res = fann_save_to_fixed(obj->pointer, lua_tostring(L, 2));
	lua_pushinteger(L, res);
	
	return 1;
}

/*! ann:run(input1, input2, ..., inputn)
 *# Evaluates the neural network for the given inputs.
 *x xor = ann:run(-1, 1)
 *-
 */
static int lfann_net_run(lua_State *L) 
{	
	struct fann **ann;
		
	int nin, nout, i;
	fann_type *input, *output;
	
	ann = lua_touserdata(L, 1);	
	
	nin = lua_gettop(L) - 1;
	if(nin != fann_get_num_input(*ann))
		luaL_error(L, "wrong number of inputs: expected %d, got %d", fann_get_num_input(*ann), nin);
		
	nout = fann_get_num_output(*ann);

	input = calloc(nin, sizeof *input);
	if(!input)
		luaL_error(L, "out of memory");
		
	for(i = 0; i < nin; i++)
	{
		input[i] = luaL_checknumber(L, i + 2);		
	}	
	
	output = fann_run(*ann, input);	
	for(i = 0; i < nout; i++)
	{	
		lua_pushnumber(L, output[i]);
	}
			
	free(input);
	
	return nout;
}

static int lfann_net_init_weights(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	fann_init_weights(obj1->pointer, obj2->pointer);
	
	return 0;
}

static int lfann_net_randomize_weights(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_randomize_weights(obj->pointer, lua_tonumber(L, 2), lua_tonumber(L, 3));
	
	return 0;
}

static int lfann_net_set_weight(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_weight(obj->pointer, lua_tointeger(L, 2) - 1, lua_tointeger(L, 3) - 1,
		lua_tonumber(L, 4));
	
	return 0;
}

static int lfann_net_get_MSE(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	float mse = fann_get_MSE(obj->pointer);
	lua_pushnumber(L, mse);
	
	return 1;
}

static int lfann_net_get_bit_fail(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	unsigned int bit = fann_get_bit_fail(obj->pointer);
	lua_pushinteger(L, bit);
	
	return 1;
}

static int lfann_net_reset_MSE(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	fann_reset_MSE(obj->pointer);
	
	return 0;
}

static int lfann_net_set_callback(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
    CallbackInfo* info = fann_get_user_data(obj->pointer);
    if(info) free_info(info); 
    
	if(lua_type(L, 2) == LUA_TFUNCTION)
	{
		/* User passed the function to call */
		luaL_checktype(L, 2, LUA_TFUNCTION);
	
		CallbackInfo* info = calloc(1, sizeof(CallbackInfo));
		info->L = L;
		
		/* Reference the function */
		lua_pushvalue(L, 2);
		info->function_ref = luaL_ref(L, LUA_REGISTRYINDEX);
		
		/* Reference the userdata */
		lua_pushvalue(L, 3);
		info->ud_ref = luaL_ref(L, LUA_REGISTRYINDEX);
		
		fann_set_user_data(obj->pointer, info);
	}
	
	fann_set_callback(obj->pointer, priv_callback_handle);
	
	return 0;
}

static int lfann_net_test_data(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	float mse = fann_test_data(obj1->pointer, obj2->pointer);
	lua_pushnumber(L, mse);
	
	return 1;
}

static int lfann_net_get_layer_array(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int n_layers = fann_get_num_layers(obj->pointer);
	unsigned int* layers= calloc(n_layers, sizeof(unsigned int));
	fann_get_layer_array(obj->pointer, layers);
	
	lua_newtable(L);
	
	int i;
	for(i = 1; i <= n_layers; ++i)
	{
		lua_pushinteger(L, layers[i - 1]);
		lua_rawseti(L, -2, i);
	}
		
	free(layers);
	
	return 1;
}

static int lfann_net_get_bias_array(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int n_layers = fann_get_num_layers(obj->pointer);
	unsigned int* layers= calloc(n_layers, sizeof(unsigned int));
	fann_get_bias_array(obj->pointer, layers);
	
	lua_newtable(L);
	
	int i;
	for(i = 1; i <= n_layers; ++i)
	{
		lua_pushinteger(L, layers[i - 1]);
		lua_rawseti(L, -2, i);
	}
		
	free(layers);
	
	return 1;
}

static int lfann_net_get_connection_array(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int n_conn = fann_get_total_connections(obj->pointer);
	struct fann_connection* conn = calloc(n_conn, sizeof(struct fann_connection));
	fann_get_connection_array(obj->pointer, conn);
	
	/* get the min and max weights too. evil */
	fann_type min_w = 32000, max_w = -32000;
	
	/* build a graph in the form graph[from][to] = [weight] */
	lua_newtable(L);
	
	int i;
	for(i = 0; i < n_conn; ++i)
	{
		lua_pushinteger(L, conn[i].from_neuron + 1);
		lua_rawget(L, -2);
		
		if(lua_isnil(L, -1))
		{
			/* First connection of the neuron */
			lua_pop(L, 1); /* pop the nil */
			lua_newtable(L);
			
			/* Set in the main table */
			lua_pushinteger(L, conn[i].from_neuron + 1);
			lua_pushvalue(L, -2);
			lua_rawset(L, -4);
		}
		
		lua_pushinteger(L, conn[i].to_neuron + 1);
		lua_pushnumber(L, conn[i].weight);
		lua_rawset(L, -3);
		lua_pop(L, 1); /* Pop the neuron table */
		
		if(conn[i].weight < min_w ) min_w = conn[i].weight;
		if(conn[i].weight > max_w) max_w = conn[i].weight;
	}
	
	free(conn);
	lua_pushnumber(L, min_w);
	lua_pushnumber(L, max_w);
	
	return 3;
}

/* parameters */

static int lfann_net_set_training_algorithm(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_training_algorithm(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_training_algorithm(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	lua_pushinteger(L, fann_get_training_algorithm(obj->pointer));
	
	return 1;
}

static int lfann_net_set_learning_rate(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_learning_rate(obj->pointer, lua_tonumber(L, 2));

	return 0;
}

static int lfann_net_get_learning_rate(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_learning_rate(obj->pointer);
	lua_pushnumber(L, res);

	return 1;
}

static int lfann_net_set_learning_momentum(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_learning_momentum(obj->pointer, lua_tonumber(L, 2));

	return 0;
}

static int lfann_net_get_learning_momentum(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_learning_momentum(obj->pointer);
	lua_pushnumber(L, res);

	return 1;
}

static int lfann_net_set_activation_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_function(obj->pointer, lua_tointeger(L, 2),
		lua_tointeger(L, 3) - 1, lua_tointeger(L, 4) - 1);
	
	return 0;
}

static int lfann_net_get_activation_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	int res = fann_get_activation_function(obj->pointer, lua_tointeger(L, 2) - 1,
		lua_tointeger(L, 3) - 1);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_activation_function_layer(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_function_layer(obj->pointer, lua_tointeger(L, 2),
		lua_tointeger(L, 3) - 1);
	
	return 0;
}

static int lfann_net_set_activation_function_hidden(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_function_hidden(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_set_activation_function_output(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_function_output(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_set_activation_steepness(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_steepness(obj->pointer, lua_tonumber(L, 2),
		lua_tointeger(L, 3) - 1, lua_tointeger(L, 4) - 1);
	
	return 0;
}

static int lfann_net_get_activation_steepness(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_type res = fann_get_activation_steepness(obj->pointer, lua_tointeger(L, 2) - 1,
		lua_tointeger(L, 3) - 1);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_activation_steepness_layer(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	luaL_checktype(L, 3, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_steepness_layer(obj->pointer, lua_tonumber(L, 2),
		lua_tointeger(L, 3) - 1);
	
	return 0;
}

static int lfann_net_set_activation_steepness_hidden(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_steepness_hidden(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_set_activation_steepness_output(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_activation_steepness_output(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_set_train_error_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_train_error_function(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_train_error_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	int func = fann_get_train_error_function(obj->pointer);
	lua_pushinteger(L, func);
	
	return 1;
}

static int lfann_net_set_train_stop_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_train_stop_function(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_train_stop_function(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	int func = fann_get_train_stop_function(obj->pointer);
	lua_pushinteger(L, func);
	
	return 1;
}

static int lfann_net_get_bit_fail_limit(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	fann_type bit = fann_get_bit_fail_limit(obj->pointer);
	lua_pushnumber(L, bit);
	
	return 1;
}

static int lfann_net_set_bit_fail_limit(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_bit_fail_limit(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_quickprop_decay(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float bit = fann_get_quickprop_decay(obj->pointer);
	lua_pushnumber(L, bit);
	
	return 1;
}

static int lfann_net_set_quickprop_decay(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_quickprop_decay(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_quickprop_mu(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_quickprop_mu(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_quickprop_mu(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_quickprop_mu(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_rprop_increase_factor(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_rprop_increase_factor(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_rprop_increase_factor(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_rprop_increase_factor(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_rprop_decrease_factor(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_rprop_decrease_factor(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_rprop_decrease_factor(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_rprop_decrease_factor(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_rprop_delta_min(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_rprop_delta_min(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_rprop_delta_min(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_rprop_delta_min(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_rprop_delta_max(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_rprop_delta_max(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_rprop_delta_max(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_rprop_delta_max(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_rprop_delta_zero(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	float res = fann_get_rprop_delta_zero(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_rprop_delta_zero(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_rprop_delta_zero(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_print_parameters(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	
	Object* obj = lua_touserdata(L, 1);
	fann_print_parameters(obj->pointer);
	
	return 0;
}

static int lfann_net_get_num_input(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_num_input(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_get_num_output(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_num_output(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_get_total_neurons(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_total_neurons(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_get_total_connections(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_total_connections(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_get_network_type(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_network_type(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_get_connection_rate(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	float res = fann_get_connection_rate(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_get_num_layers(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_get_num_layers(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

/* cascade */

static int lfann_net_cascade_train_on_data(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	luaL_checktype(L, 5, LUA_TNUMBER);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	fann_cascadetrain_on_data(obj1->pointer, obj2->pointer, lua_tointeger(L, 3),
		lua_tointeger(L, 4), lua_tonumber(L, 5));
		
	return 0;
}

static int lfann_net_cascade_train_on_file(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TSTRING);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	luaL_checktype(L, 5, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_cascadetrain_on_file(obj->pointer, lua_tostring(L, 2), lua_tointeger(L, 3),
		lua_tointeger(L, 4), lua_tonumber(L, 5));
	
	return 0;	
}

static int lfann_net_get_cascade_output_change_fraction(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	float res = fann_get_cascade_output_change_fraction(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_output_change_fraction(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_output_change_fraction(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_output_stagnation_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_output_stagnation_epochs(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_output_stagnation_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_output_stagnation_epochs(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_candidate_stagnation_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_candidate_stagnation_epochs(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_candidate_stagnation_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_candidate_stagnation_epochs(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_candidate_change_fraction(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	float res = fann_get_cascade_candidate_change_fraction(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_candidate_change_fraction(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_candidate_change_fraction(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_weight_multiplier(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	fann_type res = fann_get_cascade_weight_multiplier(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_weight_multiplier(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_weight_multiplier(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_candidate_limit(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	fann_type res = fann_get_cascade_candidate_limit(obj->pointer);
	lua_pushnumber(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_candidate_limit(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_candidate_limit(obj->pointer, lua_tonumber(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_max_out_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_max_out_epochs(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_max_out_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_max_out_epochs(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_max_cand_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_max_cand_epochs(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_max_cand_epochs(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_max_cand_epochs(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_num_candidates(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_num_candidates(obj->pointer);
	lua_pushinteger(L, res);
	
	return  1;
}

static int lfann_net_get_cascade_activation_functions_count(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_activation_functions_count(obj->pointer);
	lua_pushinteger(L, res);
	
	return  1;
}

static int lfann_net_get_cascade_activation_functions(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int num = fann_get_cascade_activation_functions_count(obj->pointer);
	int* res = (int*)fann_get_cascade_activation_functions(obj->pointer);
	
	lua_newtable(L);
	
	int i;
	for(i = 0; i < num; ++i)
	{
		lua_pushinteger(L, i + 1);
		lua_pushinteger(L, res[i]);
		lua_rawset(L, -3);
	}
	
	return 1;
}

static int lfann_net_set_cascade_activation_functions(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TTABLE);
	
	Object* obj = lua_touserdata(L, 1);
	int count = lua_objlen(L, 2), i;
	int* funcs = calloc(count, sizeof(int));

	for(i = 1; i <= count; ++i)
	{
		lua_pushinteger(L, i);
		lua_rawget(L, 2);
		
		if(lua_type(L, -1) == LUA_TNUMBER)
		{
			funcs[i - 1] = lua_tointeger(L, -1);
			lua_pop(L, 1);
		}
		else
		{
			free(funcs);
			luaL_error(L, "The table values must be numbers");
		}
	}
	
	fann_set_cascade_activation_functions(obj->pointer, (void*)funcs, count);
	free(funcs);
	
	return 0;
}

static int lfann_net_get_cascade_num_candidate_groups(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_num_candidate_groups(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}

static int lfann_net_set_cascade_num_candidate_groups(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TNUMBER);
	
	Object* obj = lua_touserdata(L, 1);
	fann_set_cascade_num_candidate_groups(obj->pointer, lua_tointeger(L, 2));
	
	return 0;
}

static int lfann_net_get_cascade_activation_steepnesses(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int num = fann_get_cascade_activation_steepnesses_count(obj->pointer);
	fann_type* res = fann_get_cascade_activation_steepnesses(obj->pointer);
	
	lua_newtable(L);
	
	int i;
	for(i = 0; i < num; ++i)
	{
		lua_pushinteger(L, i + 1);
		lua_pushnumber(L, res[i]);
		lua_rawset(L, -3);
	}
	
	return 1;
}

static int lfann_net_set_cascade_activation_steepnesses(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TTABLE);
	
	Object* obj = lua_touserdata(L, 1);
	int count = lua_objlen(L, 2), i;
	fann_type* res = calloc(count, sizeof(fann_type));

	for(i = 1; i <= count; ++i)
	{
		lua_pushinteger(L, i);
		lua_rawget(L, 2);
		
		if(lua_type(L, -1) == LUA_TNUMBER)
		{
			res[i - 1] = lua_tonumber(L, -1);
			lua_pop(L, 1);
		}
		else
		{
			free(res);
			luaL_error(L, "The table values must be numbers");
		}
	}
	
	fann_set_cascade_activation_steepnesses(obj->pointer, res, count);
	free(res);
	
	return 0;
}

static int lfann_net_get_cascade_activation_steepnesses_count(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	unsigned int res = fann_get_cascade_activation_steepnesses_count(obj->pointer);
	lua_pushinteger(L, res);
	
	return  1;
}

/*
static int lfann_net_scale_train(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	fann_scale_train(obj1->pointer, obj2->pointer);
	
	return 0;
}

static int lfann_net_descale_train(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	fann_descale_train(obj1->pointer, obj2->pointer);
	
	return 0;
}

static int lfann_net_set_scaling_params(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	luaL_checktype(L, 5, LUA_TNUMBER);
	luaL_checktype(L, 6, LUA_TNUMBER);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	int res = fann_set_scaling_params(obj1->pointer, obj2->pointer, lua_tonumber(L, 3),
		lua_tonumber(L, 4), lua_tonumber(L, 5), lua_tonumber(L, 6));

	lua_pushinteger(L, res);
	return 1;
}

static int lfann_net_set_input_scaling_params(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	int res = fann_set_input_scaling_params(obj1->pointer, obj2->pointer, lua_tonumber(L, 3),
		lua_tonumber(L, 4));

	lua_pushinteger(L, res);
	return 1;
}

static int lfann_net_set_output_scaling_params(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	luaL_checktype(L, 2, LUA_TUSERDATA);
	luaL_checktype(L, 3, LUA_TNUMBER);
	luaL_checktype(L, 4, LUA_TNUMBER);
	
	Object* obj1 = lua_touserdata(L, 1);
	Object* obj2 = lua_touserdata(L, 2);
	
	int res = fann_set_output_scaling_params(obj1->pointer, obj2->pointer, lua_tonumber(L, 3),
		lua_tonumber(L, 4));

	lua_pushinteger(L, res);
	return 1;
}

static int lfann_net_clear_scaling_params(lua_State* L)
{
	luaL_checktype(L, 1, LUA_TUSERDATA);
	Object* obj = lua_touserdata(L, 1);
	
	int res = fann_clear_scaling_params(obj->pointer);
	lua_pushinteger(L, res);
	
	return 1;
}
*/
