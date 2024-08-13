module value;
import std::collections::list;
import rc;
import code;
import vm;

def ValueRc = Rc(<Value>);
def FunctionRc = Rc(<Function>);
def NativeFunction = fn Value!(Vm*, List(<Value>));
enum ValueType : char {
    NULL,
    INT,
    FLOAT,
    BOOL,
    CHAR,
    STRING,
    VECTOR,
    FUNCTION,
    NATIVE_FUNCTION,
}
union ValueVariant {
    int int_value;
    float float_value;
    bool bool_value;
    char char_value;
    DString string_value;
    List(<Value>)* vector_value;
    FunctionRc* function_value;
    NativeFunction* native_function_value;
}
struct Function {
    ClosureRc* closure;
    List(<ValueRc*>) upvalues;
}
fn void Function.free(Function* self) {
    self.closure.free();
    foreach (i, rc: self.upvalues) {
        rc.free();
    }
}
struct Value {
    ValueType type;
    ValueVariant value;
}
fn void Value.free(Value* self) {
    switch (self.type) {
        case ValueType.VECTOR:
            foreach (i, value: self.value.vector_value) {
                value.free();
            }
            self.value.vector_value.free();
        case ValueType.FUNCTION:
            self.value.function_value.free();
        default:
    }
}
fn bool Value.to_bool(Value* self) {
    switch (self.type) {
        case ValueType.NULL:
            return false;
        case ValueType.INT:
            return self.value.int_value != 0;
        case ValueType.FLOAT:
            return self.value.float_value != 0.0;
        case ValueType.BOOL:
            return self.value.bool_value;
        case ValueType.CHAR:
            return self.value.char_value != 0;
        case ValueType.STRING:
            return self.value.string_value.len() > 0;
        case ValueType.VECTOR:
            return !self.value.vector_value.is_empty();
        default:
            return true;
    }
}
fn bool Value.eq(Value* self, Value* other) {
    if (self.type != other.type) return false;
    switch (self.type) {
        case ValueType.NULL:
            return true;
        case ValueType.INT:
            return self.value.int_value == other.value.int_value;
        case ValueType.FLOAT:
            return self.value.float_value == other.value.float_value;
        case ValueType.BOOL:
            return self.value.bool_value == other.value.bool_value;
        case ValueType.CHAR:
            return self.value.char_value == other.value.char_value;
        case ValueType.STRING:
            return self.value.string_value == other.value.string_value;
        case ValueType.VECTOR:
            return self.value.vector_value == other.value.vector_value;
        case ValueType.FUNCTION:
            return self.value.function_value == other.value.function_value;
        case ValueType.NATIVE_FUNCTION:
            return self.value.native_function_value == other.value.native_function_value;
    }
}
fn String Value.to_string(Value* self) {
    switch (self.type) {
        case ValueType.NULL:
            return "null";
        case ValueType.INT:
            return string::new_format("%d", self.value.int_value);
        case ValueType.FLOAT:
            return string::new_format("%f", self.value.float_value);
        case ValueType.BOOL:
            if (self.value.bool_value) { return "true"; }
            else { return "false"; }
        case ValueType.CHAR:
            return string::new_format("%c", self.value.char_value);
        case ValueType.STRING:
            return self.value.string_value.str_view();
        case ValueType.VECTOR:
            return string::new_format("%s", self.value.vector_value);
        case ValueType.FUNCTION:
            return string::new_format("fn:%08x", self.value.function_value.value);
        case ValueType.NATIVE_FUNCTION:
            return string::new_format("fn:%08x", self.value.native_function_value);
    }
}