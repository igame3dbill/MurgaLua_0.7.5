/*
 	This file is part of fann.

	fann is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	fann is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.

	You should have received a copy of the GNU Lesser General Public License
	along with fann.  If not, see <http://www.gnu.org/licenses/>.

	Copyright (C) 2009 Lucas Hermann Negri
*/

#include "lfann.h"
#include "net.c"
#include "data.c"
#include "extension.c"

/* Interface */

static void priv_register(lua_State* L, const char* name, const char* mt, 
	const luaL_reg* methods, lua_CFunction gc, lua_CFunction tostring)
{
	/* Register the methods */
	luaL_register(L, name, methods);
	
	/* Register the metatable */
	luaL_newmetatable(L, mt);
	
	/* __index */
	lua_pushliteral(L, "__index");
	lua_pushvalue(L, -3);
	lua_rawset(L, -3);
	
	/* __gc */
	lua_pushliteral(L, "__gc");
	lua_pushcfunction(L, gc);
	lua_rawset(L, -3);
	
	/* __tostring */
	lua_pushliteral(L, "__tostring");
	lua_pushcfunction(L, tostring);
	lua_rawset(L, -3);
}

static const struct luaL_reg lfann [] =
{
	{NULL, NULL}
};

static const struct luaL_reg data [] =
{
	{"read_from_file", lfann_data_read_from_file},
	{"create_from_callback", lfann_data_create_from_callback},
	{"save", lfann_data_save},
	{"save_to_fixed", lfann_data_save_to_fixed},
	{"shuffle", lfann_data_shuffle},
	{"scale", lfann_data_scale},
	{"scale_input", lfann_data_scale_input},
	{"scale_output", lfann_data_scale_output},
	{"merge", lfann_data_merge},
	{"duplicate", lfann_data_duplicate},
	{"subset", lfann_data_subset},
	{"lenght", lfann_data_lenght},
	{"num_input", lfann_data_num_input},
	{"num_output", lfann_data_num_output},
	{"get_row", lfann_data_get_row},
	{"get_bounds", lfann_data_get_bounds},
	{"get_bounds_input", lfann_data_get_bounds_input},
	{"get_bounds_output", lfann_data_get_bounds_output},
	{NULL, NULL}
};

static const struct luaL_reg net [] =
{
	{"create_standard", lfann_net_create_standard},
	{"create_sparse", lfann_net_create_sparse},
	{"create_shortcut", lfann_net_create_shortcut},
	{"create_from_file", lfann_net_create_from_file},
	{"print_connections", lfann_net_print_connections},
	{"train_on_file", lfann_net_train_on_file},
	{"train_on_data", lfann_net_train_on_data},
	{"train_epoch", lfann_net_train_epoch},
	{"save", lfann_net_save},
	{"save_to_fixed", lfann_net_save_to_fixed},
	{"run", lfann_net_run},
	{"init_weights", lfann_net_init_weights},
	{"randomize_weights", lfann_net_randomize_weights},
	{"print_parameters", lfann_net_print_parameters},
	{"set_weight", lfann_net_set_weight},
	{"get_MSE", lfann_net_get_MSE},
	{"get_training_algorithm", lfann_net_get_training_algorithm},
	{"set_training_algorithm", lfann_net_set_training_algorithm},
	{"reset_MSE", lfann_net_reset_MSE},
	{"get_bit_fail", lfann_net_get_bit_fail},
	{"set_callback", lfann_net_set_callback},
	{"test_data", lfann_net_test_data},
	{"get_network_type", lfann_net_get_network_type},
	{"set_learning_rate", lfann_net_set_learning_rate},
	{"get_learning_rate", lfann_net_get_learning_rate},
	{"set_learning_momentum", lfann_net_set_learning_momentum},
	{"get_learning_momentum", lfann_net_get_learning_momentum},
	{"set_activation_function", lfann_net_set_activation_function},
	{"get_activation_function", lfann_net_get_activation_function},
	{"set_activation_function_hidden", lfann_net_set_activation_function_hidden},
	{"set_activation_function_layer", lfann_net_set_activation_function_layer},
	{"set_activation_function_output", lfann_net_set_activation_function_output},
	{"set_activation_steepness", lfann_net_set_activation_steepness},
	{"get_activation_steepness", lfann_net_get_activation_steepness},
	{"set_activation_steepness_hidden", lfann_net_set_activation_steepness_hidden},
	{"set_activation_steepness_layer", lfann_net_set_activation_steepness_layer},
	{"set_activation_steepness_output", lfann_net_set_activation_steepness_output},
	{"set_train_error_function", lfann_net_set_train_error_function},
	{"get_train_error_function", lfann_net_get_train_error_function},
	{"set_train_stop_function", lfann_net_set_train_stop_function},
	{"get_train_stop_function", lfann_net_get_train_stop_function},
	{"set_bit_fail_limit", lfann_net_set_bit_fail_limit},
	{"get_bit_fail_limit", lfann_net_get_bit_fail_limit},
	{"set_quickprop_decay", lfann_net_set_quickprop_decay},
	{"get_quickprop_decay", lfann_net_get_quickprop_decay},
	{"set_quickprop_mu", lfann_net_set_quickprop_mu},
	{"get_quickprop_mu", lfann_net_get_quickprop_mu},
	{"set_rprop_increase_factor", lfann_net_set_rprop_increase_factor},
	{"get_rprop_increase_factor", lfann_net_get_rprop_increase_factor},
	{"set_rprop_decrease_factor", lfann_net_set_rprop_decrease_factor},
	{"get_rprop_decrease_factor", lfann_net_get_rprop_decrease_factor},
	{"get_rprop_delta_min", lfann_net_get_rprop_delta_min},
	{"set_rprop_delta_min", lfann_net_set_rprop_delta_min},
	{"get_rprop_delta_max", lfann_net_get_rprop_delta_max},
	{"set_rprop_delta_max", lfann_net_set_rprop_delta_max},
	{"set_rprop_delta_zero", lfann_net_set_rprop_delta_zero},
	{"get_rprop_delta_zero", lfann_net_get_rprop_delta_zero},
	{"get_num_input", lfann_net_get_num_input},
	{"get_num_output", lfann_net_get_num_output},
	{"get_total_neurons", lfann_net_get_total_neurons},
	{"get_total_connections", lfann_net_get_total_connections},
	{"get_connection_rate", lfann_net_get_connection_rate},
	{"get_num_layers", lfann_net_get_num_layers},
	{"get_layer_array", lfann_net_get_layer_array},
	{"get_bias_array", lfann_net_get_bias_array},
	{"get_connection_array", lfann_net_get_connection_array},
	{"cascade_train_on_data", lfann_net_cascade_train_on_data},
	{"cascade_train_on_file", lfann_net_cascade_train_on_file},
	{"set_cascade_output_change_fraction", lfann_net_set_cascade_output_change_fraction},
	{"get_cascade_output_change_fraction", lfann_net_get_cascade_output_change_fraction},
	{"set_cascade_output_stagnation_epochs", lfann_net_set_cascade_output_stagnation_epochs},
	{"get_cascade_output_stagnation_epochs", lfann_net_get_cascade_output_stagnation_epochs},
	{"set_cascade_candidate_change_fraction", lfann_net_set_cascade_candidate_change_fraction},
	{"get_cascade_candidate_change_fraction", lfann_net_get_cascade_candidate_change_fraction},
	{"set_cascade_candidate_stagnation_epochs", lfann_net_set_cascade_candidate_stagnation_epochs},
	{"get_cascade_candidate_stagnation_epochs", lfann_net_get_cascade_candidate_stagnation_epochs},
	{"set_cascade_weight_multiplier", lfann_net_set_cascade_weight_multiplier},
	{"get_cascade_weight_multiplier", lfann_net_get_cascade_weight_multiplier},
	{"set_cascade_candidate_limit", lfann_net_set_cascade_candidate_limit},
	{"get_cascade_candidate_limit", lfann_net_get_cascade_candidate_limit},
	{"get_cascade_max_cand_epochs", lfann_net_get_cascade_max_cand_epochs},
	{"set_cascade_max_cand_epochs", lfann_net_set_cascade_max_cand_epochs},
	{"get_cascade_max_out_epochs", lfann_net_get_cascade_max_out_epochs},
	{"set_cascade_max_out_epochs", lfann_net_set_cascade_max_out_epochs},
	{"get_cascade_num_candidates", lfann_net_get_cascade_num_candidates},
	{"get_cascade_activation_functions_count", lfann_net_get_cascade_activation_functions_count},
	{"get_cascade_activation_functions", lfann_net_get_cascade_activation_functions},
	{"set_cascade_activation_functions", lfann_net_set_cascade_activation_functions},
	{"get_cascade_activation_steepnesses_count", lfann_net_get_cascade_activation_steepnesses_count},
	{"get_cascade_activation_steepnesses", lfann_net_get_cascade_activation_steepnesses},
	{"set_cascade_activation_steepnesses", lfann_net_set_cascade_activation_steepnesses},
	{"get_cascade_activation_steepnesses_count", lfann_net_get_cascade_activation_steepnesses_count},
	{"set_cascade_num_candidate_groups", lfann_net_set_cascade_num_candidate_groups},
	{"get_cascade_num_candidate_groups", lfann_net_get_cascade_num_candidate_groups},
	{NULL, NULL}
};

int luaopen_lfann(lua_State *L)
{
	fann_set_error_log(&err_handler, NULL);
	
	luaL_register(L, "fann", lfann);
	int top = lua_gettop(L);
	priv_register(L, "fann.Net", "lfannNeT", net, lfann_net_gc, lfann_net_tostring);
	priv_register(L, "fann.Data", "lfannDaTa", data, lfann_data_gc, lfann_data_tostring);
	lua_settop(L, top);
	
	/* activation_functipn_enum */
	lua_pushliteral(L, "LINEAR"); lua_pushnumber(L, FANN_LINEAR); lua_rawset(L, -3);
	lua_pushliteral(L, "THRESHOLD"); lua_pushnumber(L, FANN_THRESHOLD); lua_rawset(L, -3);
	lua_pushliteral(L, "THRESHOLD_SYMMETRIC"); lua_pushnumber(L, FANN_THRESHOLD_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "SIGMOID"); lua_pushnumber(L, FANN_SIGMOID); lua_rawset(L, -3);
	lua_pushliteral(L, "SIGMOID_STEPWISE"); lua_pushnumber(L, FANN_SIGMOID_STEPWISE); lua_rawset(L, -3);
	lua_pushliteral(L, "SIGMOID_SYMMETRIC"); lua_pushnumber(L, FANN_SIGMOID_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "GAUSSIAN"); lua_pushnumber(L, FANN_GAUSSIAN); lua_rawset(L, -3);
	lua_pushliteral(L, "GAUSSIAN_SYMMETRIC"); lua_pushnumber(L, FANN_GAUSSIAN_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "ELLIOT"); lua_pushnumber(L, FANN_ELLIOT); lua_rawset(L, -3);
	lua_pushliteral(L, "ELLIOT_SYMMETRIC"); lua_pushnumber(L, FANN_ELLIOT_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "LINEAR_PIECE"); lua_pushnumber(L, FANN_LINEAR_PIECE); lua_rawset(L, -3);
	lua_pushliteral(L, "LINEAR_PIECE_SYMMETRIC"); lua_pushnumber(L, FANN_LINEAR_PIECE_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "SIN"); lua_pushnumber(L, FANN_SIN); lua_rawset(L, -3);
	lua_pushliteral(L, "SIN_SYMMETRIC"); lua_pushnumber(L, FANN_SIN_SYMMETRIC); lua_rawset(L, -3);
	lua_pushliteral(L, "COS"); lua_pushnumber(L, FANN_COS); lua_rawset(L, -3);
	lua_pushliteral(L, "COS_SYMMETRIC"); lua_pushnumber(L, FANN_COS_SYMMETRIC); lua_rawset(L, -3);

	/* training_algorithm_enum */
	lua_pushliteral(L, "TRAIN_INCREMENTAL"); lua_pushnumber(L, FANN_TRAIN_INCREMENTAL); lua_rawset(L, -3);
	lua_pushliteral(L, "TRAIN_BATCH"); lua_pushnumber(L, FANN_TRAIN_BATCH); lua_rawset(L, -3);
	lua_pushliteral(L, "TRAIN_RPROP"); lua_pushnumber(L, FANN_TRAIN_RPROP); lua_rawset(L, -3);
	lua_pushliteral(L, "TRAIN_QUICKPROP"); lua_pushnumber(L, FANN_TRAIN_QUICKPROP); lua_rawset(L, -3);

	/* error_function_enum */
	lua_pushliteral(L, "ERRORFUNC_LINEAR"); lua_pushnumber(L, FANN_ERRORFUNC_LINEAR); lua_rawset(L, -3);
	lua_pushliteral(L, "ERRORFUNC_TANH"); lua_pushnumber(L, FANN_ERRORFUNC_TANH); lua_rawset(L, -3);

	/* stop_function_enum */
	lua_pushliteral(L, "STOPFUNC_MSE"); lua_pushnumber(L, FANN_STOPFUNC_MSE); lua_rawset(L, -3);
	lua_pushliteral(L, "STOPFUNC_BIT"); lua_pushnumber(L, FANN_STOPFUNC_BIT); lua_rawset(L, -3);
	
	/* network_type_enum */
	lua_pushliteral(L, "NETTYPE_LAYER"); lua_pushnumber(L, FANN_NETTYPE_LAYER); lua_rawset(L, -3);
	lua_pushliteral(L, "NETTYPE_SHORTCUT"); lua_pushnumber(L, FANN_NETTYPE_SHORTCUT); lua_rawset(L, -3);
	
	/* lfann_errno_enum */
	lua_pushliteral(L, "E_NO_ERROR"); lua_pushnumber(L, FANN_E_NO_ERROR); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_OPEN_CONFIG_R"); lua_pushnumber(L, FANN_E_CANT_OPEN_CONFIG_R); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_OPEN_CONFIG_W"); lua_pushnumber(L, FANN_E_CANT_OPEN_CONFIG_W); lua_rawset(L, -3);
	lua_pushliteral(L, "E_WRONG_CONFIG_VERSION"); lua_pushnumber(L, FANN_E_WRONG_CONFIG_VERSION); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_READ_CONFIG"); lua_pushnumber(L, FANN_E_CANT_READ_CONFIG); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_READ_NEURON"); lua_pushnumber(L, FANN_E_CANT_READ_NEURON); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_READ_CONNECTIONS"); lua_pushnumber(L, FANN_E_CANT_READ_CONNECTIONS); lua_rawset(L, -3);
	lua_pushliteral(L, "E_WRONG_NUM_CONNECTIONS"); lua_pushnumber(L, FANN_E_WRONG_NUM_CONNECTIONS); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_OPEN_TD_W"); lua_pushnumber(L, FANN_E_CANT_OPEN_TD_W); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_OPEN_TD_R"); lua_pushnumber(L, FANN_E_CANT_OPEN_TD_R); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_READ_TD"); lua_pushnumber(L, FANN_E_CANT_READ_TD); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_ALLOCATE_MEM"); lua_pushnumber(L, FANN_E_CANT_ALLOCATE_MEM); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_TRAIN_ACTIVATION"); lua_pushnumber(L, FANN_E_CANT_TRAIN_ACTIVATION); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_USE_ACTIVATION"); lua_pushnumber(L, FANN_E_CANT_USE_ACTIVATION); lua_rawset(L, -3);
	lua_pushliteral(L, "E_TRAIN_DATA_MISMATCH"); lua_pushnumber(L, FANN_E_TRAIN_DATA_MISMATCH); lua_rawset(L, -3);
	lua_pushliteral(L, "E_CANT_USE_TRAIN_ALG"); lua_pushnumber(L, FANN_E_CANT_USE_TRAIN_ALG); lua_rawset(L, -3);
	lua_pushliteral(L, "E_TRAIN_DATA_SUBSET"); lua_pushnumber(L, FANN_E_TRAIN_DATA_SUBSET); lua_rawset(L, -3);
	lua_pushliteral(L, "E_INDEX_OUT_OF_BOUND"); lua_pushnumber(L, FANN_E_INDEX_OUT_OF_BOUND); lua_rawset(L, -3);
	lua_pushliteral(L, "E_SCALE_NOT_PRESENT"); lua_pushnumber(L, FANN_E_SCALE_NOT_PRESENT); lua_rawset(L, -3);
	
	return 1;
}
