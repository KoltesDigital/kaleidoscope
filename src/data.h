#ifndef DATA_H_
#define DATA_H_

#include <libfirm/firm.h>

// AST expressions
typedef enum {
	EXPR_NUM, // number expression
	EXPR_ID, // identifier expression
	EXPR_BIN, // binary expression
	EXPR_CALL // call expression
} expr_kind;

typedef struct expr_t {
	struct expr_t *next; // next item in linked list
	expr_kind which; // its kind
} expr_t;

typedef struct {
	expr_t *first;
	expr_t *last;
	int count;
} expr_list_t;

// look at this! inheritance in object-oriented C!
typedef struct {
	struct expr_t *next;
	expr_kind which;
	double val; // the double value of a number
} num_expr_t;

typedef struct {
	struct expr_t *next;
	expr_kind which;
	char *name; // the name of a variable
} id_expr_t;

typedef struct {
	struct expr_t *next;
	expr_kind which;
	char op; // the binary operator
	expr_t *lhs, *rhs; // the left and right hand side
} bin_expr_t;

typedef struct {
	struct expr_t *next;
	expr_kind which;
	char *callee; // the function to be called
	expr_list_t *parameters;
} call_expr_t;

typedef struct parameter_t {
	struct parameter_t *next;
	char *name;
	ir_node *proj;
} parameter_t;

typedef struct {
	parameter_t *first;
	parameter_t *last;
	int count;
} parameter_list_t;

typedef struct prototype_t {
	struct prototype_t *next;
	char *name;
	parameter_list_t *parameters;
	ir_entity *entity;
} prototype_t;

typedef struct {
	prototype_t *first;
	prototype_t *last;
	int count;
} prototype_list_t;

// basic types
extern ir_mode *d_mode;
extern ir_type *d_type;

extern ir_mode *i_mode;
extern ir_type *i_type;

// node which receives the newly created nodes
extern ir_node *cur_store;

// prototype list
extern prototype_list_t prototypes;

// transforms AST into nodes
ir_node *handle_expr(expr_t *expr, parameter_list_t *parameters);

#endif /* DATA_H_ */
