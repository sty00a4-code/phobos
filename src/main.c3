module phobos;
import std::io;
import vm;
import rc;
import value;
import code;

fn void main(String[] args)
{
	Value! res = vm::run({
		{
			code::int_(0x01, 3),
			code::int_(0x02, 3),
			code::bin(BinaryOperation.MUL, 0x00, 0x01, 0x02),
			code::ret(0x00),
		},
		{ "hello" },
		{},
		{},
		3,
	});
	if (try value = res) {
		io::printfn("%s", value.to_string());
	} else if (catch f = res) {
		io::printfn("%s", f);
	}
}
