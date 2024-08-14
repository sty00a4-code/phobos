module ast;
import position;
import token;
import std::collections::list;

struct Statement {
    StatementKind kind;
    StatementValue value;
}
enum StatementKind : char {
    LET,
    ASSIGN,
    RETURN,
}
union StatementValue {
    StatementLet let;
    StatementAssign assign;
    Located(<Expression>) return_expr;
}
struct StatementLet {
    Located(<String>) ident;
    Located(<Expression>) expr;
}
fn Located(<Statement>) statement_let(Located(<String>) ident, Located(<Expression>) expr, Position(<Statement>) pos) {
    Statement node;
    node.kind = StatementKind.LET;
    node.value.let = {
        ident,
        expr,
    };
    return position::located(<Statement>)(node, pos);
}
struct StatementAssign {
    Located(<Path>) path;
    Located(<Expression>) expr;
}
fn Located(<Statement>) statement_assign(Located(<Path>) path, Located(<Expression>) expr, Position(<Statement>) pos) {
    Statement node;
    node.kind = StatementKind.ASSIGN;
    node.value.assign = {
        path,
        expr,
    };
    return position::located(<Statement>)(node, pos);
}
fn Located(<Statement>) statement_return(Located(<Expression>) return_expr, Position(<Statement>) pos) {
    Statement node;
    node.kind = StatementKind.RETURN;
    node.value.return_expr = return_expr;
    return position::located(<Statement>)(node, pos);
}

struct Expression {
    ExpressionKind kind;
    ExpressionValue value;
}
enum ExpressionKind : char {
    ATOM,
    BINARY,
    UNARY,
}
union ExpressionValue {
    Atom atom;
    ExpressionBinary binary;
    ExpressionUnary unary;
}
fn Located(<Expression>) expression_atom(Atom atom, Position(<Expression>) pos) {
    Expression node;
    node.kind = ExpressionKind.ATOM;
    node.value.atom = atom;
    return position::located(<Expression>)(node, pos);
}
struct ExpressionBinary {
    Located(<String>) op;
    Located(<Expression*>) left;
    Located(<Expression*>) right;
}
fn Located(<Expression>) expression_binary(Located(<String>) op, Located(<Expression*>) left, Located(<Expression*>) right, Position(<Expression>) pos) {
    Expression node;
    node.kind = ExpressionKind.BINARY;
    node.value.binary = {
        op,
        left,
        right,
    };
    return position::located(<Expression>)(node, pos);
}
struct ExpressionUnary {
    Located(<String>) op;
    Located(<Expression*>) right;
}
fn Located(<Expression>) expression_unary(Located(<String>) op, Located(<Expression*>) right, Position(<Expression>) pos) {
    Expression node;
    node.kind = ExpressionKind.BINARY;
    node.value.unary = {
        op,
        right,
    };
    return position::located(<Expression>)(node, pos);
}

struct Atom {
    AtomKind kind;
    AtomValue value;
}
enum AtomKind : char {
    IDENT,
    INT,
    FLOAT,
    BOOL,
    CHAR,
    STRING,
    EXPRESSION,
    VECTOR,
    OBJECT,
}
union AtomValue {
    String ident;
    int int_token;
    float float_token;
    bool bool_token;
    char char_token;
    String string;
    Located(<Expression*>) expr;
    List(<Expression>) vector;
    List(<ObjectEntry>) object;
}
fn Located(<Atom>) atom_ident(String ident, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.IDENT;
    node.value.ident = ident;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_int(int int_token, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.INT;
    node.value.int_token = int_token;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_float(float float_token, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.FLOAT;
    node.value.float_token = float_token;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_bool(bool bool_token, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.BOOL;
    node.value.bool_token = bool_token;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_char(char char_token, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.CHAR;
    node.value.char_token = char_token;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_string(String string, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.STRING;
    node.value.string = string;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_expression(Located(<Expression*>) expr, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.EXPRESSION;
    node.value.expr = expr;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_vector(List(<Expression>) vector, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.VECTOR;
    node.value.vector = vector;
    return position::located(<Atom>)(node, pos);
}
fn Located(<Atom>) atom_object(List(<ObjectEntry>) object, Position(<Atom>) pos) {
    Atom node;
    node.kind = AtomKind.OBJECT;
    node.value.object = object;
    return position::located(<Atom>)(node, pos);
}
struct ObjectEntry {
    Located(<String>) key;
    Located(<Expression>) value;
}

struct Path {
    PathKind kind;
    PathValue value;
}
enum PathKind : char {
    IDENT,
    FIELD,
    INDEX,
}
union PathValue {
    String ident;
    PathField field;
    PathIndex index;
}
fn Located(<Path>) path_ident(String ident, Position(<Path>) pos) {
    Path node;
    node.kind = PathKind.IDENT;
    node.value.ident = ident;
    return position::located(<Path>)(node, pos);
}
struct PathField {
    Located(<PathKind*>) head;
    Located(<String>) field;
}
fn Located(<Path>) path_field(PathField field, Position(<Path>) pos) {
    Path node;
    node.kind = PathKind.FIELD;
    node.value.field = field;
    return position::located(<Path>)(node, pos);
}
struct PathIndex {
    Located(<PathKind*>) head;
    Located(<Expression>) index;
}
fn Located(<Path>) path_index(PathIndex index, Position(<Path>) pos) {
    Path node;
    node.kind = PathKind.FIELD;
    node.value.index = index;
    return position::located(<Path>)(node, pos);
}