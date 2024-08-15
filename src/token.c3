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
const String[] KEYWORDS = {
    "let",
};
macro bool String[].contains(&self, String* value) {
    foreach(i, element: self) {
        if (element == *value) return true;
    }
    return false;
}
fn String Token.to_str(&self) {
    switch (self.kind) {
        case TokenKind.IDENT:
            return self.value.word;
        case TokenKind.KEYWORD:
            return self.value.word;
        case TokenKind.SYMBOL:
            return self.value.symbol;
        case TokenKind.INT:
            return string::new_format("%d", self.value.int_value);
        case TokenKind.FLOAT:
            return string::new_format("%f", self.value.float_value);
        case TokenKind.STRING:
            return string::new_format("\"%s\"", self.value.string);
        case TokenKind.CHAR:
            return string::new_format("'%s'", self.value.char_value);
    }
}
fn bool Token.eq(&self, Token* other) {
    if (self.kind != other.kind) return false;
    switch (self.kind) {
        case TokenKind.IDENT:
            return self.value.word == other.value.word;
        case TokenKind.KEYWORD:
            return self.value.word == other.value.word;
        case TokenKind.SYMBOL:
            return self.value.symbol == other.value.symbol;
        case TokenKind.INT:
            return self.value.int_value == other.value.int_value;
        case TokenKind.FLOAT:
            return self.value.float_value == other.value.float_value;
        case TokenKind.STRING:
            return self.value.string == other.value.string;
        case TokenKind.CHAR:
            return self.value.char_value == other.value.char_value;
    }
}
fn Token ident(String ident) {
    Token token;
    token.kind = TokenKind.IDENT;
    if (KEYWORDS.contains(&ident)) token.kind = TokenKind.KEYWORD;
    token.value.word = ident;
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
    token.kind = TokenKind.FLOAT;
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
