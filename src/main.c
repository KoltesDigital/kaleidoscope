#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <ctype.h>
#include <libfirm/firm.h>
#include <libfirm/irdump.h>
#include <data.h>

// prototype of bison-generated parser function
int yyparse();

int main(int argc, char **argv) {
	int dump = 0;
	char *out_name = NULL;

	// parse options in command line
	int opt;
	opterr = 0;

	while ((opt = getopt(argc, argv, "do:")) != -1) {
		switch (opt) {
		case 'd':
			dump = 1;
			break;

		case 'o':
			out_name = strdup(optarg);
			break;

		case '?':
			if (optopt == 'o')
				fprintf(stderr, "Option -%c requires an argument.\n", optopt);
			else if (isprint(optopt))
				fprintf(stderr, "Unknown option `-%c'.\n", optopt);
			else
				fprintf(stderr, "Unknown option character `\\x%x'.\n", optopt);
			return 1;

		default:
			abort();
		}
	}

	if (optind >= argc) {
		printf("Usage: %s [-o file] file\n", argv[0]);
		return 1;
	}

	// open program
	char *filename = argv[optind];

	if (freopen(filename, "r", stdin) == NULL) {
		fprintf(stderr, "%s: File %s cannot be opened.\n", argv[0], filename);
		return 1;
	}

	// initialize libfirm
	ir_init();

	// create the program
	char *prog_name = NULL;

	char *lastDot = strrchr(filename, '.');
	if (lastDot != NULL) {
		int base = (int)(lastDot - filename);

		prog_name = (char*)malloc(base + 1);
		strncpy(prog_name, filename, base);
		prog_name[base] = '\0';
	} else {
		prog_name = strdup(filename);
	}

	if (out_name == NULL) {
		out_name = (char*)malloc(strlen(prog_name) + 3);
		strcpy(out_name, prog_name);
		strcat(out_name, ".s");
	}

	new_ir_prog(prog_name);

	// initialize list of prototypes
	prototypes.first = NULL;
	prototypes.count = 0;

	// initialize basic types
	d_mode = get_modeD();
	d_type = new_type_primitive(d_mode);

	i_mode = get_modeIs();
	i_type = new_type_primitive(i_mode);

	// create the graphs
	yyparse();

	// dump when called with the proper option
	if (dump) {
		dump_all_ir_graphs("");
	}

	// generate ASM code
	FILE *out = NULL;
	if ((out = fopen(out_name, "w")) == NULL) {
		fprintf(stderr, "Could not open output file %s.\n", out_name);
		return 1;
	}

	be_lower_for_target();

	be_main(out, prog_name);

	// so long, and thanks for all the fish
	ir_finish();

	return 0;
}

