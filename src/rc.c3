module rc(<Type>);

struct Rc {
    Type* value;
    usz count;
}
fn Rc(<Type>)* init() {
    Rc(<Type>) rc;
    rc.value = mem::new(Type);
    rc.count++;
    return mem::new(Rc(<Type>), rc);
}
fn Rc(<Type>)* new(Type value) {
    Rc(<Type>) rc;
    rc.value = mem::new(Type, value);
    rc.count++;
    return mem::new(Rc(<Type>), rc);
}
fn Rc(<Type>)* clone(Rc(<Type>)* rc) {
    rc.count++;
    return rc;
}
fn void Rc(<Type>).free(Rc(<Type>)* rc) {
    rc.count--;
    if (rc.count == 0) {
        mem::free(rc);
    }
}
fn void free(Rc(<Type>)* rc) => Rc(<Type>).free(rc);
