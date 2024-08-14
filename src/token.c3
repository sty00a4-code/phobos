module token;
import position;

struct Token {
    TokenKind kind;
    TokenValue value;
}
enum TokenKind {
    IDENT,
    KEYWORD,
    SYMBOL,
    INT,
    FLOAT,
    STRING,
    CHAR,
}
union TokenValue {
    String word;
    String symbol;
    int int_value;
    float float_value;
    String string;
    char char_value;
}
fn Token ident(String ident) {
    Token token;
    token.kind = TokenKind.IDENT;
    token.value.word = ident;
    return token;
}
fn Token keyword(String keyword) {
    Token token;
    token.kind = TokenKind.KEYWORD;
    token.value.word = keyword;
    return token;
}
fn Token symbol(String symbol) {
    Token token;
    token.kind = TokenKind.SYMBOL;
    token.value.symbol = symbol;
    return token;
}
fn Token int_token(int int_value) {
    Token token;
    token.kind = TokenKind.INT;
    token.value.int_value = int_value;
    return token;
}
fn Token float_token(float float_value) {
    Token token;
    token.kind = TokenKind.INT;
    token.value.float_value = float_value;
    return token;
}
fn Token string(String string) {
    Token token;
    token.kind = TokenKind.STRING;
    token.value.string = string;
    return token;
}
fn Token char_token(char char_value) {
    Token token;
    token.kind = TokenKind.CHAR;
    token.value.char_value = char_value;
    return token;
}
