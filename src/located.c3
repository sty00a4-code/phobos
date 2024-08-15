module located(<Type>);
import position;

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