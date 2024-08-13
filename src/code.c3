import std::io;
import rc;

def ByteCode = ulong;
fn void char[8].print_bytecode(char[8] self) {
    io::printfn(
        "%02x %02x %02x %02x %02x %02x %02x %02x",
        self[0],
        self[1],
        self[2],
        self[3],
        self[4],
        self[5],
        self[6],
        self[7],
    );
}
fn char[8] ByteCode.to_bytes(ByteCode* self) {
    return {
        (char) ((0xff00000000000000 & *self) >> (8 * 7)),
        (char) ((0x00ff000000000000 & *self) >> (8 * 6)),
        (char) ((0x0000ff0000000000 & *self) >> (8 * 5)),
        (char) ((0x000000ff00000000 & *self) >> (8 * 4)),
        (char) ((0x00000000ff000000 & *self) >> (8 * 3)),
        (char) ((0x0000000000ff0000 & *self) >> (8 * 2)),
        (char) ((0x000000000000ff00 & *self) >> 8),
        (char)  (0x00000000000000ff & *self)
    };
}
def Register = char;
enum Instruction : char {
    NOP,

    CALL0,
    CALL0_DST,
    CALL1,
    CALL1_DST,
    CALL_ARGS,
    CALL_ARGS_DST,
    RET0,
    RET,

    NULL,
    INT,
    FLOAT,
    BOOL,
    CHAR,
    STR,
    VEC,
    FUNC,

    MOV,
    UPVALUE,
    SETUPVALUE,
    FIELD,
    SETFIELD,

    BIN,
    UN,
}
enum BinaryOperation : char {
    ADD,
    SUB,
    MUL,
    DIV,
    MOD,
    POW,
    EE,
    NE,
    LT,
    GT,
    LE,
    GE,
}
enum UnaryOperation : char {
    NEG,
}
fn ByteCode nop() {
    ByteCode instr = (ByteCode)(char) Instruction.NOP;
    return instr << (8 * 7);
}
fn ByteCode call0(Register func) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL0;
    return (instr << (8 * 7)) | ((ByteCode) func << (8 * 6));
}
fn ByteCode call0_dst(Register func, Register dst) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL0_DST;
    return (instr << (8 * 7)) | ((ByteCode) func << (8 * 6)) | ((ByteCode) dst << (8 * 5));
}
fn ByteCode call1(Register func, Register src) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL1;
    return (instr << (8 * 7)) | ((ByteCode) func << (8 * 6)) | ((ByteCode) src << (8 * 5));
}
fn ByteCode call1_dst(Register func, Register src, Register dst) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL1_DST;
    return (instr << (8 * 7)) | ((ByteCode) func << (8 * 6)) | ((ByteCode) src << (8 * 5)) | ((ByteCode) dst << (8 * 4));
}
fn ByteCode call_args(Register func, char start, char amount) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL_ARGS;
    return
        (instr << (8 * 7)) |
        ((ByteCode) func << (8 * 6)) |
        ((ByteCode) start << (8 * 5)) |
        ((ByteCode) amount << (8 * 4));
}
fn ByteCode call_args_dst(Register func, char start, char amount, Register dst) {
    ByteCode instr = (ByteCode)(char) Instruction.CALL_ARGS_DST;
    return
        (instr << (8 * 7)) |
        ((ByteCode) func << (8 * 6)) |
        ((ByteCode) start << (8 * 5)) |
        ((ByteCode) amount << (8 * 4)) |
        ((ByteCode) dst << (8 * 3));
}
fn ByteCode ret0() {
    ByteCode instr = (ByteCode)(char) Instruction.RET0;
    return (instr << (8 * 7));
}
fn ByteCode ret(Register src) {
    ByteCode instr = (ByteCode)(char) Instruction.RET;
    return (instr << (8 * 7)) | ((ByteCode) src << (8 * 6));
}
fn ByteCode mov(Register dst, Register src) {
    ByteCode instr = (ByteCode)(char) Instruction.MOV;
    return (instr << (8 * 7)) | ((ByteCode) dst << (8 * 6)) | ((ByteCode) src << (8 * 5));
}
fn ByteCode null_(Register dst) {
    ByteCode instr = (ByteCode)(char) Instruction.NULL;
    return (instr << (8 * 7));
}
fn ByteCode int_(Register dst, int value) {
    ByteCode instr = (ByteCode)(char) Instruction.INT;
    return
        (instr << (8 * 7)) |
        ((ByteCode) dst << (8 * 6)) |
        ((ByteCode) value << (8 * 2));
}
fn ByteCode bool_(Register dst, bool value) {
    ByteCode instr = (ByteCode)(char) Instruction.BOOL;
    return (instr << (8 * 7)) | ((ByteCode) dst << (8 * 6));
}
fn ByteCode char_(Register dst, char value) {
    ByteCode instr = (ByteCode)(char) Instruction.CHAR;
    return (instr << (8 * 7)) | ((ByteCode) value << (8 * 6));
}
fn ByteCode str(Register dst, char idx) {
    ByteCode instr = (ByteCode)(char) Instruction.STR;
    return (instr << (8 * 7)) | ((ByteCode) dst << (8 * 6)) | ((ByteCode) idx << (8 * 5));
}
fn ByteCode func(Register dst, char idx) {
    ByteCode instr = (ByteCode)(char) Instruction.FUNC;
    return (instr << (8 * 7)) | ((ByteCode) dst << (8 * 6)) | ((ByteCode) idx << (8 * 5));
}
fn ByteCode bin(BinaryOperation op, Register dst, Register left, Register right) {
    ByteCode instr = (ByteCode)(char) Instruction.BIN;
    return
        (instr << (8 * 7)) |
        ((ByteCode)(char) op << (8 * 6)) |
        ((ByteCode) dst << (8 * 5)) |
        ((ByteCode) left << (8 * 4)) |
        ((ByteCode) right << (8 * 3));
}
fn ByteCode un(UnaryOperation op, Register dst, Register src) {
    ByteCode instr = (ByteCode)(char) Instruction.UN;
    return
        (instr << (8 * 7)) |
        ((ByteCode)(char) op << (8 * 6)) |
        ((ByteCode) dst << (8 * 5)) |
        ((ByteCode) src << (8 * 4));
}
struct Closure {
    ByteCode[] code;
    String[] strings;
    ClosureRc*[] closures;
    UpValue[] upvalues;
    usz registers;
}
fn void Closure.free(Closure* self) {
    foreach (i, rc: self.closures) {
        rc.free();
    }
}
struct UpValue {
    Register register;
    usz depth;
}

def ClosureRc = Rc(<Closure>);