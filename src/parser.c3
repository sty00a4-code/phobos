module parser;
import located;
import position;
import token;
import ast;
import std::collections::list;
import std::io;

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
    return self.parse_binary(0);
}
fault LayerFault {
    OUT_OF_RANGE,
}
const String[][] BINARY_LAYERS = {
    {"&&", "||"},
    {"==", "!=", "<", ">", "<=", ">="},
    {"+", "-"},
    {"*", "/", "%"},
    {"^"},
};
fn String[]*! binary_layer(usz layer) {
    if (layer >= BINARY_LAYERS.len) return LayerFault.OUT_OF_RANGE?;
    return &BINARY_LAYERS[layer];
}
const String[][] UNARY_LAYERS = {
    {"-"},
};
fn String[]*! unary_layer(usz layer) {
    if (layer >= UNARY_LAYERS.len) return LayerFault.OUT_OF_RANGE?;
    return &UNARY_LAYERS[layer];
}
fn Located(<Expression>)! Parser.parse_binary(&self, usz layer) {
    String[]*! ops = binary_layer(layer);
    if (catch f = ops) {
        return self.parse_unary(0);
    }
    Located(<Expression>) left = self.parse_binary(layer + 1)!;
    while (@ok(self.peek())) {
        Located(<Token>) token = self.peek()!!;
        if (!(ops.contains(&token.value.value.word) || ops.contains(&token.value.value.symbol))) break;
        self.next()!;
        Located(<String>) op = located::located(<String>)(token.value.to_str(), token.pos);
        Located(<Expression*>) right;
        {
            Located(<Expression>) expr = self.parse_binary(layer + 1)!;
            right.value = mem::new(Expression, expr.value);
            right.pos = expr.pos;
        }
        Located(<Expression*>) new_left;
        new_left.value = mem::new(Expression, left.value);
        new_left.pos = left.pos;
        Expression binary;
        binary.kind = ExpressionKind.BINARY;
        binary.value.binary = {
            op,
            new_left,
            right,
        };
        left.value = binary;
    }
    return left;
}
fn Located(<Expression>)! Parser.parse_unary(&self, usz layer) {
    String[]*! ops = unary_layer(layer);
    if (catch f = ops) {
        Located(<Atom>) atom = self.parse_atom()!;
        return ast::expression_atom(atom.value, atom.pos);
    }
    if (try token = self.peek()) {
        if (ops.contains(&token.value.value.word) || ops.contains(&token.value.value.symbol)) {
            self.next()!;
            Located(<String>) op = located::located(<String>)(token.value.to_str(), token.pos);
            Located(<Expression*>) right;
            {
                Located(<Expression>) expr = self.parse_binary(layer + 1)!;
                right.value = mem::new(Expression, expr.value);
                right.pos = expr.pos;
            }
            Expression unary;
            unary.kind = ExpressionKind.UNARY;
            unary.value.unary = {
                op,
                right,
            };
            return located::located(<Expression>)(unary, token.pos);
        }
    }
    return self.parse_unary(layer + 1);
}
fn Located(<Atom>)! Parser.parse_atom(&self) {
    return ParserFault.UNEXPECTED_TOKEN?;
}

fn Located(<String>)! Parser.parse_ident(&self) {
    Located(<Token>) token = self.expect_kind(TokenKind.IDENT)!;
    return ast::ident(token.value.value.word, token.pos);
}