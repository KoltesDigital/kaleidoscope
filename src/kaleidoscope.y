/* Grammar for Kaleidoscope */

%{
#include <libfirm/firm.h>
#include "data.h"

#define YY_NO_UNPUT

int yyerror(char *s);
int yylex(void);
%}

%union{
	double				val;
	char*				str;
	expr_t*				expr;
	expr_list_t*		expr_list;
	parameter_list_t*	param_list;
	prototype_t*		prototype;
}

%start	input 

%token	<val>			DOUBLE_LITERAL
%token	<str>			IDENTIFIER

%type	<expr>			expr
%type	<expr_list>		expr_list
%type	<param_list>	param_list
%type	<prototype>		prototype

%token	DEF
%token	EXTERN
%token	MAIN

%left	'+'
%left	'*'

%%

input		:
			|	stat_list
			;

stat_list	:	stat
			|	stat_list stat
			;

stat		:	MAIN expr
				{
					// create a new prototype taking no parameter and returning an integer
					ir_type *type = new_type_method(0, 1);
					set_method_res_type(type, 0, i_type);
					ir_entity *entity = new_entity(get_glob_type(), new_id_from_str("main"), type);
					
					// create the function graph
					ir_graph *fun_graph = new_ir_graph(entity, 0);
					set_current_ir_graph(fun_graph);
					
					// update the pointer to the main node
					cur_store = get_irg_initial_mem(fun_graph);
					
					// create an empty parameter list
					parameter_list_t *parameters = (parameter_list_t *)malloc(sizeof(parameter_list_t));
					parameters->first = NULL;
					parameters->count = 0;
					
					// handle body but don't care about the result
					handle_expr($2, parameters);
					
					// actually the result is always 0
					ir_node *node = new_Const(new_tarval_from_long(0, i_mode));
					ir_node **result = &node;
					ir_node *ret = new_Return(cur_store, 1, result);
					
					ir_node *end = get_irg_end_block(fun_graph);
					
					// set the return node to be its predecessor
					add_immBlock_pred(end, ret);	  
					
					// mature blocks
					mature_immBlock(get_r_cur_block(fun_graph));
					mature_immBlock(end);
					
					// set as the main graph of the program
					set_irp_main_irg(fun_graph);
					
					// finalize the construction
					irg_finalize_cons(fun_graph);
					
				}
			|	DEF prototype expr
				{
					// append prototype to the list
					prototype_t *prototype = $2;
					
					if (prototypes.count == 0) {
						prototypes.first = prototype;
						prototypes.last = prototype;
					} else {
						prototypes.last->next = prototype;
					}
					
					prototypes.last = prototype;
					++prototypes.count;
					
					// create the function graph
					ir_graph *fun_graph = new_ir_graph(prototype->entity, prototype->parameters->count);
					set_current_ir_graph(fun_graph);
					
					// update the pointer to the main node
					cur_store = get_irg_initial_mem(fun_graph);
					
					// create the projs for the parameters
					if (prototype->parameters->count > 0) {
						// keep track of the current block
						ir_node *block = get_r_cur_block(fun_graph);
						
						// set the start block to be the current block
						set_r_cur_block(fun_graph, get_irg_start_block(fun_graph));
						
						// get a reference to the arguments node
						ir_node *args = get_irg_args(fun_graph);
						
						// create a projection node for each parameter
						int i = 0;
						for (parameter_t *parameter = prototype->parameters->first; parameter != NULL; parameter = parameter->next, ++i) {
							parameter->proj = new_Proj(args, d_mode, i);
						}
						
						// restore the original block
						set_r_cur_block(fun_graph, block);
					}
					
					// the body is just an expression
					ir_node *node = handle_expr($3, prototype->parameters);
					
					// the result of the function is the result of the body
					ir_node **result = &node;
					ir_node *ret = new_Return(cur_store, 1, result);
					
					ir_node *end = get_irg_end_block(fun_graph);
					
					// set the return node to be its predecessor
					add_immBlock_pred(end, ret);
					
					// mature blocks
					mature_immBlock(get_r_cur_block(fun_graph));		  
					mature_immBlock(end);
					
					// finalize the construction
					irg_finalize_cons(fun_graph);
				}
			|	EXTERN prototype
				{
					// append prototype to the list
					if (prototypes.count == 0) {
						prototypes.first = $2;
						prototypes.last = $2;
					} else {
						prototypes.last->next = $2;
					}
					
					prototypes.last = $2;
					++prototypes.count;
				}
			;

prototype	:	IDENTIFIER '(' param_list ')'
				{
					// defines prototype
					prototype_t *prototype = (prototype_t *)malloc(sizeof(prototype_t));
					prototype->next = NULL;
					prototype->name = $1;
					prototype->parameters = $3;
					
					ir_type *type = new_type_method(prototype->parameters->count, 1);
					for (int i = 0; i < prototype->parameters->count; ++i) {
						set_method_param_type(type, i, d_type);
					}
					set_method_res_type(type, 0, d_type);
					
					prototype->entity = new_entity(get_glob_type(), new_id_from_str(prototype->name), type);

					$$ = prototype;
				}
			;

param_list	:	
				{
					// empty list
					parameter_list_t *list = (parameter_list_t *)malloc(sizeof(parameter_list_t));
					list->first = NULL;
					list->count = 0;
					
					$$ = list;
				}
			|	IDENTIFIER
				{
					// list with one parameter
					parameter_t *parameter = (parameter_t *)malloc(sizeof(parameter_t));
					parameter->next = NULL;
					parameter->name = $1;
					
					parameter_list_t *list = (parameter_list_t *)malloc(sizeof(parameter_list_t));
					list->first = parameter;
					list->last = parameter;
					list->count = 1;
					
					$$ = list;
				}
			|	param_list ',' IDENTIFIER
				{
					// append parameter to the list
					parameter_t *parameter = (parameter_t *)malloc(sizeof(parameter_t));
					parameter->next = NULL;
					parameter->name = $3;
					
					parameter_list_t *list = $1;
					list->last->next = parameter;
					list->last = parameter;
					++list->count;
					
					$$ = list;
				}
			;

expr_list	:	
				{
					// empty list
					expr_list_t *list = (expr_list_t *)malloc(sizeof(expr_list_t));
					list->first = NULL;
					list->count = 0;
					
					$$ = list;
				}
			|	expr
				{
					// list with one expr
					expr_list_t *list = (expr_list_t *)malloc(sizeof(expr_list_t));
					list->first = $1;
					list->last = $1;
					list->count = 1;
					
					$$ = list;
				}
			|	expr_list ',' expr
				{
					// append expr to the list
					expr_list_t *list = $1;
					list->last->next = $3;
					list->last = $3;
					++list->count;
					
					$$ = list;
				}
			;
			
expr		:	DOUBLE_LITERAL
				{
					// constant value
					num_expr_t *expr = (num_expr_t *)malloc(sizeof(num_expr_t));
					expr->next = NULL;
					expr->which = EXPR_NUM;
					expr->val = $1;
					$$ = (expr_t *)expr;
				}
			|	IDENTIFIER
				{
					// variable
					id_expr_t *expr = (id_expr_t *)malloc(sizeof(id_expr_t));
					expr->next = NULL;
					expr->which = EXPR_ID;
					expr->name = $1;
					$$ = (expr_t *)expr;
				}
			|	IDENTIFIER '(' expr_list ')'
				{
					// function call
					call_expr_t *expr = (call_expr_t *)malloc(sizeof(call_expr_t));
					expr->next = NULL;
					expr->which = EXPR_CALL;
					expr->callee = $1;
					expr->parameters = $3;
					$$ = (expr_t *)expr;
				}
			|	expr '+' expr
				{
					// addition
					bin_expr_t *expr = (bin_expr_t *)malloc(sizeof(bin_expr_t));
					expr->next = NULL;
					expr->which = EXPR_BIN;
					expr->op = '+';
					expr->lhs = $1;
					expr->rhs = $3;
					$$ = (expr_t *)expr;
				}
			|	expr '*' expr
				{
					// multiplication
					bin_expr_t *expr = (bin_expr_t *)malloc(sizeof(bin_expr_t));
					expr->next = NULL;
					expr->which = EXPR_BIN;
					expr->op = '*';
					expr->lhs = $1;
					expr->rhs = $3;
					$$ = (expr_t *)expr;
				}
			;

%%

int yyerror(char *str)
{
	extern int yylineno;	// defined and maintained in lex.c
	extern char *yytext;	// defined and maintained in lex.c
	
	fprintf(stderr, "ERROR: %s at symbol \"%s\" on line %d.\n", str, yytext, yylineno);
	
	exit(1);
	
	return 0;
}
