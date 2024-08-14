module position(<Type>);

struct Position {
    usz ln;
    usz col;
}
struct Located {
    Type value;
    Position pos;
}
fn Located(<Type>) located(Type value, Position pos) {
    return {
        value,
        pos,
    };
}