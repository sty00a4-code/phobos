module phobos;
import std::io;
import std::collections::list;
import vm;
import rc;
import position;
import located;
import token;
import lexer;
import ast;
import parser;
import value;
import code;

fault ArgumentFault {
	NO_PATH_PROVIDED
}
fn void! main(String[] args)
{
	if (args.len < 2) return ArgumentFault.NO_PATH_PROVIDED?;
	String path = args[1];
	DString! text = read_file(path);
	if (catch f = text) {
		io::printfn("ERROR: %s", f);
		return f?;
	}
	List(<Located(<Token>)>)! tokens = lexer::lex(text.str_view());
	if (catch f = tokens) {
		io::printfn("ERROR: %s", f);
		return f?;
	}
	Parser parser;
	parser.tokens = tokens;
	Located(<Statement>)! statement = parser.parse_let();
	if (catch f = statement) {
		io::printfn("ERROR: %s", f);
		return f?;
	}
}

fn DString! read_file(String path) {
	DString text;
	File file = io::file::open(path, "r")!;
	while (!file.eof()) {
		if (try line = io::treadline(&file)) {
			text.append_chars(line);
			text.append_char('\n');
		} else {
			break;
		}
	}
	file.close()!;
	return text;
}