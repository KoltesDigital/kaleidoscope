#include <string.h>
#include <data.h>

ir_mode *d_mode;
ir_type *d_type;

ir_mode *i_mode;
ir_type *i_type;

ir_node *cur_store;

prototype_list_t prototypes;

ir_node *handle_expr(expr_t *expr, parameter_list_t *parameters) {
	switch (expr->which) {
	case EXPR_NUM: {
		num_expr_t *num = (num_expr_t*) expr;
		return new_Const(new_tarval_from_double(num->val, d_mode));
	}

	case EXPR_ID: {
		id_expr_t *id = (id_expr_t*) expr;
		for (parameter_t *parameter = parameters->first; parameter != NULL; parameter = parameter->next) {
			if (!strcmp(parameter->name, id->name)) {
				return parameter->proj;
			}
		}
		return NULL;
	}

	case EXPR_BIN: {
		bin_expr_t *bin = (bin_expr_t*) expr;
		ir_node *lhs = handle_expr(bin->lhs, parameters);
		ir_node *rhs = handle_expr(bin->rhs, parameters);
		switch (bin->op) {
		case '+':
			return new_Add(lhs, rhs, d_mode);

		case '*':
			return new_Mul(lhs, rhs, d_mode);

		default:
			fprintf(stderr, "Invalid binary expression.\n");
			exit(1);
		}
	}

	case EXPR_CALL: {
		call_expr_t *call = (call_expr_t*) expr;

		ir_node *callee = NULL;
		ir_node **in = NULL;
		ir_node *result = NULL;
		ir_entity *entity = NULL;

		// allocate space for an array referencing the arguments
		if (call->parameters->count > 0) {
			in
					= (ir_node**) malloc(
							sizeof(ir_node**) * call->parameters->count);
		}

		// find the corresponding prototype and create a symbolic constant
		for (prototype_t *prototype = prototypes.first; prototype != NULL; prototype
				= prototype->next) {
			if (!strcmp(prototype->name, call->callee)) {
				entity = prototype->entity;
				symconst_symbol symbol;
				symbol.entity_p = entity;
				callee = new_SymConst(get_modeP(), symbol, symconst_addr_ent);
				break;
			}
		}

		if (callee != NULL) {
			// handle the arguments
			int i = 0;
			for (expr_t *e = call->parameters->first; e != NULL; e = e->next, ++i) {
				in[i] = handle_expr(e, parameters);
			}

			// create the call
			ir_node *call_node = new_Call(cur_store, callee,
					call->parameters->count, in, get_entity_type(entity));

			// update the current store
			cur_store = new_Proj(call_node, get_modeM(), pn_Call_M);

			// get the result
			ir_node *tuple = new_Proj(call_node, get_modeT(), pn_Call_T_result);
			result = new_Proj(tuple, d_mode, 0);
		} else {
			fprintf(stderr, "Cannot call unknown function \"%s\".\n", call->callee);
			exit(1);
		}

		if (in != NULL) {
			free(in);
		}

		return result;
	}

	default:
		return NULL;
	}
}
