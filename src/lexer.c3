module lexer;
import std::collections::list;
import std::io;
import position;
import located;
import token;

struct Lexer {
    String text;
    usz idx;
    usz ln;
    usz col;
}
fn Position Lexer.pos(&self) {
    return {
        self.ln,
        self.col,
    };
}
fn void Lexer.advance(&self) {
    if (try c = self.get() == '\n') {
        self.ln++;
        self.col = 0;
    } else {
        self.col++;
    }
    self.idx++;
}
fault LexerFault {
    EOF,
    BAD_CHAR,
    UNCLOSED_STRING,
}
fn char! Lexer.get(&self) {
    if (self.idx >= self.text.len) return LexerFault.EOF?;
    return self.text[self.idx];
}
fn Located(<Token>)! Lexer.next(&self) {
    do {
        if (try c = self.get()) {
            if (!c.is_space()) break;
            self.advance();
        } else {
            break;
        }
    } while (true);
    char c = self.get()!;
    Position pos = self.pos();
    self.advance();
    switch (c) {
        case '(': return located::located(<Token>)(token::symbol("("), pos);
        case ')': return located::located(<Token>)(token::symbol(")"), pos);
        case '[': return located::located(<Token>)(token::symbol("["), pos);
        case ']': return located::located(<Token>)(token::symbol("]"), pos);
        case '{': return located::located(<Token>)(token::symbol("{"), pos);
        case '}': return located::located(<Token>)(token::symbol("}"), pos);
        case '=': return located::located(<Token>)(token::symbol("="), pos);
        case '.': return located::located(<Token>)(token::symbol("."), pos);
        case ',': return located::located(<Token>)(token::symbol(","), pos);
        case '+': return located::located(<Token>)(token::symbol("+"), pos);
        case '-': return located::located(<Token>)(token::symbol("-"), pos);
        case '*': return located::located(<Token>)(token::symbol("*"), pos);
        case '/': return located::located(<Token>)(token::symbol("/"), pos);
        case '%': return located::located(<Token>)(token::symbol("%"), pos);
        case '^': return located::located(<Token>)(token::symbol("^"), pos);
        case '"':
            DString string;
            do {
                if (try next_c = self.get()) {
                    if (next_c == '"') break;
                    if (next_c == '\\') {
                        self.advance();
                        next_c = self.get()!;
                        switch (next_c) {
                            case 'n':
                                next_c = '\n';
                            case 't':
                                next_c = '\t';
                            case 'r':
                                next_c = '\r';
                            default:
                        }
                    }
                    string.append_char(next_c);
                    self.advance();
                } else {
                    return LexerFault.UNCLOSED_STRING?;
                }
            } while (true);
            self.advance();
            return located::located(<Token>)(token::string(string.str_view()), pos);
        default:
            if (c.is_digit()) {
                DString number;
                number.append_char(c);
                do {
                    if (try next_c = self.get()) {
                        if (!next_c.is_digit()) break;
                        number.append_char(c);
                        self.advance();
                    } else {
                        break;
                    }
                } while (true);
                if (try next_c = self.get()) if (next_c == '.') {
                    number.append_char('.');
                    self.advance();
                    do {
                        if (try next_c2 = self.get()) {
                            if (!next_c2.is_digit()) break;
                            number.append_char(next_c2);
                            self.advance();
                        } else {
                            break;
                        }
                    } while (true);
                    return located::located(<Token>)(token::float_token(number.str_view().to_float()!), pos);
                }
                return located::located(<Token>)(token::int_token(number.str_view().to_int()!), pos);
            } else if (c.is_alnum() || c == '_') {
                DString ident;
                ident.append_char(c);
                do {
                    if (try next_c = self.get()) {
                        if (!c.is_alnum() && c != '_') break;
                        ident.append_char(c);
                        self.advance();
                    } else {
                        break;
                    }
                } while (true);
                return located::located(<Token>)(token::ident(ident.str_view()), pos);
            }
    }
    return LexerFault.BAD_CHAR?;
}
fn List(<Located(<Token>)>)! Lexer.lex(&self) {
    List(<Located(<Token>)>) tokens;
    do {
        Located(<Token>)! token = self.next();
        if (catch f = token) {
            if (f == LexerFault.EOF) break;
            return f?;
        }
        tokens.push(token);
    } while (true);
    return tokens;
}

fn List(<Located(<Token>)>)! lex(String text) {
    Lexer lexer;
    lexer.text = text;
    List(<Located(<Token>)>)! tokens = lexer.lex()!;
    return tokens;
}