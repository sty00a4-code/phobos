module parser;
import located;
import position;
import token;
import ast;
import std::collections::list;

struct Parser {
    List(<Located(<Token>)>) tokens;
}
fault ParserFault {
    EOF,
    UNEXPECTED_TOKEN,
}
fn Located(<Token>)! Parser.next(&self) {
    if (self.tokens.is_empty()) return ParserFault.EOF?;
    return self.tokens.pop_first()!!;
}
fn Located(<Token>)! Parser.peek(&self) {
    if (self.tokens.is_empty()) return ParserFault.EOF?;
    return self.tokens.first()!!;
}
fn Located(<Token>)! Parser.expect_kind(&self, TokenKind kind) {
    Located(<Token>) token = self.next()!;
    if (token.value.kind != kind) return ParserFault.UNEXPECTED_TOKEN?;
    return token;
}
fn Located(<Token>)! Parser.expect(&self, Token expected_token) {
    Located(<Token>) token = self.next()!;
    if (!token.value.eq(&expected_token)) return ParserFault.UNEXPECTED_TOKEN?;
    return token;
}

fn Located(<Statement>)! Parser.parse_let(&self) {
    Position pos = self.expect(token::ident("let"))!.pos;
    Located(<String>) ident = self.parse_ident()!;
    self.expect(token::symbol("="))!;
    Located(<Expression>) expr = self.parse_expr()!;
    return ast::statement_let(ident, expr, pos);
}

fn Located(<Expression>)! Parser.parse_expr(&self) {
    return ParserFault.UNEXPECTED_TOKEN?;
}

fn Located(<String>)! Parser.parse_ident(&self) {
    Located(<Token>) token = self.expect_kind(TokenKind.IDENT)!;
    return ast::ident(token.value.value.word, token.pos);
}