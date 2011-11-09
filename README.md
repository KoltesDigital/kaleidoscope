Kaleidoscope
============

Kaleidoscope is a very simple programming language, and the compiler itself.

The project is actually an example about using [libfirm](http://pp.info.uni-karlsruhe.de/firm/).

This work is based on (if not copied from) a tutorial from researchers in the [Programming paradigms group](http://pp.info.uni-karlsruhe.de/) at the [Karlsruhe Institute of Technology](http://www.kit.edu/). That tutorial included the parser itself, that I replaced by flex/bison because I thought it was not the goal of the tutorial to teach about parsing code.

Installation
------------

The following tools are needed to build the project:

* gcc
* g++
* bison
* flex
* make

and [libfirm](http://pp.info.uni-karlsruhe.de/firm/).

Then, just run

	make

How it works
------------

`kaleidoscope.lex` contains the token definitions for the [lexical analyzer](http://en.wikipedia.org/wiki/Lexical_analyzer). That is, `flex` uses it to transform the Kaleidoscope code (as a plain character string) to a list of blocks which have a semantic value.

`kaleidoscope.y` is a language grammar for the [parser generator](http://en.wikipedia.org/wiki/Parser_generator). That is, `bison` uses it to transform the tokens into libfirm's graphs, finally generating an Assembly file.

During the parsing of an expression, an [abstract syntax tree](http://en.wikipedia.org/wiki/Abstract_syntax_tree) is built, because at this time the "owner" of the corresponding graph nodes is still unknown. These nodes are created on a function definition.

Language reference
------------------

`def` defines a new function. It has a prototype (a name followed by parenthesis that may enclose a list of variables), and an expression as the body (a value, an elementary operation, or a function call).

`extern` declares extern functions (with just a prototype, no body).

`#` introduces a comment: everything on the line after the sharp will be ignored by the compiler.

See the `examples` directory.

### Complete syntax

Complete syntax in EBNF (does not describe precedence and comments):

	input = {stat}
	
	stat = "main" , expr  (* main function *)
	     | "def" , prototype , expr  (* function definition *)
	     | "extern" , prototype  (* function declaration *)
	
	prototype = identifier , "(" , [ { identifier , "," } identifier ] , ")"
	
	expr = double  (* constant value *)
	     | identifier  (* variable *)
	     | identifier , "(" , [ { expr , "," } , expr ] , ")"  (* function call *)
	     | expr , binop , expr  (* binary operation *)

	binop = "+" | "*"  (* hey! this is just an example *)
	
	(* double and identifier are trivially defined *)

The syntax is split in the `.lex` and `.y` files, and is a little bit longer due to the recursive rules.
