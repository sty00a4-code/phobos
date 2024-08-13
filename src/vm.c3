module vm;
import std::collections::list;
import std::io;
import std::math;
import std::core::dstring;
import rc;
import code;
import value;


struct Vm {
    List(<CallFrame>) call_stack;
    List(<ValueRc*>) stack;
}
struct CallFrame {
    String name;
    ClosureRc* closure;
    List(<ValueRc*>) upvalues;
    bool return_value;
    Register dst;
    usz ip;
    usz stack_base;
    usz stack_top;
}
fn void Vm.call(Vm* self, String name, FunctionRc* function, List(<Value>) args) {
    usz stack_base = self.stack.len();
    usz args_len = args.len();
    for (int i = 0; i < function.value.closure.value.registers; i++) {
        Value value;
        if (i < args_len) {
            value = args.pop_first()!!;
        }
        self.stack.push(rc::new(<Value>)(value));
    }
    self.call_stack.push({
        name,
        rc::clone(<Closure>)(function.value.closure),
        function.value.upvalues,
        false,
        0,
        0,
        stack_base,
        stack_base + function.value.closure.value.registers
    });
}
fn void Vm.call_dst(Vm* self, String name, FunctionRc* function, Register dst, List(<Value>) args) {
    usz stack_base = self.stack.len();
    usz args_len = args.len();
    for (int i = 0; i < function.value.closure.value.registers; i++) {
        Value value;
        if (i < args_len) {
            value = args.pop_first()!!;
        }
        self.stack.push(rc::new(<Value>)(value));
    }
    self.call_stack.push({
        name,
        rc::clone(<Closure>)(function.value.closure),
        function.value.upvalues,
        true,
        dst,
        0,
        stack_base,
        stack_base + function.value.closure.value.registers
    });
}
fn void! Vm.return_0(Vm* self) {
    CallFrame call_frame = self.call_stack.pop()!;
    for (int i = 0; i < call_frame.closure.value.registers; i++) {
        ValueRc* stack_value = self.stack.pop()!;
        stack_value.free();
    }
    call_frame.upvalues.free();
    self.register_set(call_frame.dst, rc::init(<Value>)());
}
fn ValueRc*! Vm.return_src(Vm* self, Register src) {
    CallFrame call_frame = self.call_stack.pop()!;
    ValueRc* value;
    for (usz i = call_frame.closure.value.registers; i > 0; i--) {
        ValueRc* stack_value = self.stack.pop()!;
        if (i - 1 == src) {
            value = stack_value;
        } else {
            stack_value.free();
        }
    }
    foreach (i, upvalue: call_frame.upvalues) {
        upvalue.free();
    }
    call_frame.upvalues.free();
    self.register_set(call_frame.dst, value);
    return value;
}
fn ValueRc* Vm.register(Vm* self, Register reg) {
    CallFrame* call_frame = &self.call_stack[self.call_stack.len()];
    return self.stack[call_frame.stack_base + reg];
}
fn ValueRc* Vm.upvalue(Vm* self, char idx) {
    CallFrame* call_frame = &self.call_stack[self.call_stack.len()];
    return call_frame.upvalues[idx];
}
fn void Vm.register_set(Vm* self, Register dst, ValueRc* value) {
    CallFrame* call_frame = &self.call_stack[self.call_stack.len()];
    self.stack[call_frame.stack_base + dst] = value;
}
fn void! Vm.run(Vm* self) {
    usz stack_base = self.call_stack.len();
    if (stack_base == 0) return;
    while (stack_base >= self.call_stack.len()) {
        if (self.step()!) break;
    }
}
fault VmFault {
    ILLEGAL_BINARY_OPERATION,
    ILLEGAL_UNARY_OPERATION,
    CANNOT_CALL_TYPE,
}
fn bool! Vm.step(Vm* self) {
    CallFrame* call_frame = &self.call_stack[self.call_stack.len() - 1];
    if (call_frame.ip >= call_frame.closure.value.code.len) return true;
    char[8] bytes = call_frame.closure.value.code[call_frame.ip].to_bytes();
    // io::printf("[%d:%s] ", self.call_stack.len(), call_frame.name);
    // bytes.print_bytecode();
    call_frame.ip += 1;
    switch (bytes[0]) {
        case (char) Instruction.CALL0:
            Register func_src = bytes[1];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call("?", func, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    (*func)(self, args)!;
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.CALL0_DST:
            Register func_src = bytes[1];
            Register dst = bytes[2];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call_dst("?", func, dst, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    self.register_set(dst, rc::new(<Value>)((*func)(self, args)!));
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.CALL1:
            Register func_src = bytes[1];
            Register src = bytes[2];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            args.push(*self.register(src).value);
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call("?", func, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    (*func)(self, args)!;
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.CALL1_DST:
            Register func_src = bytes[1];
            Register src = bytes[2];
            Register dst = bytes[3];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            args.push(*self.register(src).value);
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call_dst("?", func, dst, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    self.register_set(dst, rc::new(<Value>)((*func)(self, args)!));
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.CALL_ARGS:
            Register func_src = bytes[1];
            char start = bytes[2];
            char amount = bytes[3];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            for (Register reg = start; reg < start + amount; reg++) {
                args.push(*self.register(reg).value);
            }
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call("?", func, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    (*func)(self, args)!;
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.CALL_ARGS_DST:
            Register func_src = bytes[1];
            char start = bytes[2];
            char amount = bytes[3];
            Register dst = bytes[4];
            ValueRc* value = self.register(func_src);
            List(<Value>) args;
            for (Register reg = start; reg < start + amount; reg++) {
                args.push(*self.register(reg).value);
            }
            switch (value.value.type) {
                case ValueType.FUNCTION:
                    FunctionRc* func = value.value.value.function_value;
                    self.call_dst("?", func, dst, args);
                case ValueType.NATIVE_FUNCTION:
                    NativeFunction* func = value.value.value.native_function_value;
                    self.register_set(dst, rc::new(<Value>)((*func)(self, args)!));
                default:
                    return VmFault.CANNOT_CALL_TYPE?;
            }
            return false;
        case (char) Instruction.RET0:
            self.return_0()!;
            return false;
        case (char) Instruction.RET:
            self.return_src(bytes[1])!;
            return false;
        case (char) Instruction.NULL:
            Register dst = bytes[1];
            ValueRc* value_rc = rc::init(<Value>)();
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.INT:
            Register dst = bytes[1];
            int int_value =
                ((int) bytes[2] << (8 * 3)) |
                ((int) bytes[3] << (8 * 2)) |
                ((int) bytes[4] << 8) |
                 (int) bytes[5];
            Value value;
            value.type = ValueType.INT;
            value.value.int_value = int_value;
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.FLOAT:
            Register dst = bytes[1];
            float float_value = (float)
                (((int) bytes[2] << (8 * 3)) &
                ((int) bytes[3] << (8 * 2)) &
                ((int) bytes[4] << 8) &
                 (int) bytes[5]);
            Value value;
            value.type = ValueType.FLOAT;
            value.value.float_value = float_value;
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.BOOL:
            Register dst = bytes[1];
            bool bool_value = (bytes[2] != 0);
            Value value;
            value.type = ValueType.BOOL;
            value.value.bool_value = bool_value;
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.CHAR:
            Register dst = bytes[1];
            char char_value = bytes[2];
            Value value;
            value.type = ValueType.CHAR;
            value.value.char_value = char_value;
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.STR:
            Register dst = bytes[1];
            char idx = bytes[2];
            String string = call_frame.closure.value.strings[idx];
            Value value;
            value.type = ValueType.STRING;
            value.value.string_value = dstring::new(string);
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.VEC:
            Register dst = bytes[1];
            char start = bytes[2];
            char amount = bytes[3];
            List(<Value>) values;
            for (Register reg = start; reg < start + amount; reg++) {
                values.push(*self.register(reg).value);
            }
            Value vector;
            vector.type = ValueType.VECTOR;
            vector.value.vector_value = mem::new(List(<Value>), values);
            self.register_set(dst, rc::new(<Value>)(vector));
            return false;
        case (char) Instruction.FUNC:
            Register dst = bytes[1];
            char idx = bytes[2];
            List(<ValueRc*>) upvalues;
            ClosureRc* closure = call_frame.closure.value.closures[idx];
            foreach (i, upvalue: &closure.value.upvalues ) {
                ValueRc* value = self.stack[self.call_stack[self.call_stack.len() - 1 - upvalue.depth].stack_base + upvalue.register];
                upvalues.push(value);
            }
            Value value;
            value.type = ValueType.FUNCTION;
            value.value.function_value = rc::new(<Function>)({
                closure,
                upvalues,
            });
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.MOV:
            Register dst = bytes[1];
            Register src = bytes[2];
            ValueRc* value = self.register(src);
            self.register_set(dst, value);
            return false;
        case (char) Instruction.UPVALUE:
            Register dst = bytes[1];
            char idx = bytes[2];
            ValueRc* value = self.upvalue(idx);
            self.register_set(dst, value);
            return false;
        case (char) Instruction.SETUPVALUE:
            Register idx = bytes[1];
            Register src = bytes[2];
            Value value = *self.register(src).value;
            ValueRc* upvalue = self.upvalue(idx);
            upvalue.value = mem::new(Value, value);
            return false;
        case (char) Instruction.FIELD:
            Register dst = bytes[1];
            Register head_src = bytes[2];
            char idx = bytes[3];
            // get field
            return false;
        case (char) Instruction.SETFIELD:
            Register head_src = bytes[1];
            char idx = bytes[2];
            Register src = bytes[3];
            // set field
            return false;
        case (char) Instruction.BIN:
            BinaryOperation op = (BinaryOperation) bytes[1];
            Register dst = bytes[2];
            Register left_reg = bytes[3];
            Register right_reg = bytes[4];
            Value* left = self.register(left_reg).value;
            Value* right = self.register(right_reg).value;
            Value value;
            switch (op) {
                case BinaryOperation.ADD:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.INT;
                        value.value.int_value = left.value.int_value + right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value + right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) left.value.int_value + right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value + (float) right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.SUB:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.INT;
                        value.value.int_value = left.value.int_value - right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value - right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) left.value.int_value - right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value - (float) right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.MUL:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.INT;
                        value.value.int_value = left.value.int_value * right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value * right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) left.value.int_value * right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value * (float) right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.DIV:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.INT;
                        value.value.int_value = left.value.int_value / right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value / right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) left.value.int_value / right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value / (float) right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.MOD:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.INT;
                        value.value.int_value = left.value.int_value % right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value % right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) left.value.int_value % right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = left.value.float_value % (float) right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.POW:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) math::pow((double) left.value.int_value, (double) right.value.int_value);
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) math::pow((double) left.value.float_value, (double) right.value.float_value);
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) math::pow((double) left.value.int_value, (double) right.value.float_value);
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.FLOAT;
                        value.value.float_value = (float) math::pow((double) left.value.float_value, (double) right.value.int_value);
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.EE:
                    value.type = ValueType.BOOL;
                    value.value.bool_value = left.eq(right);
                case BinaryOperation.NE:
                    value.type = ValueType.BOOL;
                    value.value.bool_value = !left.eq(right);
                case BinaryOperation.LT:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value < right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value < right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value < right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value < right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.GT:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value > right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value > right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value > right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value > right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.LE:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value <= right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value <= right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value <= right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value <= right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
                case BinaryOperation.GE:
                    if (left.type == ValueType.INT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value >= right.value.int_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value >= right.value.float_value;
                    } else if (left.type == ValueType.INT && right.type == ValueType.FLOAT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.int_value >= right.value.float_value;
                    } else if (left.type == ValueType.FLOAT && right.type == ValueType.INT) {
                        value.type = ValueType.BOOL;
                        value.value.bool_value = left.value.float_value >= right.value.int_value;
                    } else {
                        return VmFault.ILLEGAL_BINARY_OPERATION?;
                    }
            }
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
        case (char) Instruction.UN:
            UnaryOperation op = (UnaryOperation) bytes[1];
            Register dst = bytes[2];
            Register right_reg = bytes[4];
            Value* right = self.register(right_reg).value;
            Value value;
            switch (op) {
                case UnaryOperation.NEG:
                    switch (right.type) {
                        case ValueType.INT:
                            value.type = ValueType.INT;
                            value.value.int_value = -right.value.int_value;
                        case ValueType.FLOAT:
                            value.type = ValueType.FLOAT;
                            value.value.float_value = -right.value.float_value;
                        default:
                            return VmFault.ILLEGAL_UNARY_OPERATION?;
                    }
            }
            ValueRc* value_rc = rc::new(<Value>)(value);
            self.register_set(dst, value_rc);
            return false;
    }
    return false;
}

fn Value! run(Closure closure) {
    Vm vm;
    FunctionRc* phobos = rc::new(<Function>)({
        rc::new(<Closure>)({
            {},
            {},
            {},
            {},
            1
        }),
        {},
    });
    FunctionRc* func = rc::new(<Function>)({
        rc::new(<Closure>)(closure),
        {},
    });
	vm.call_dst("<phobos>", phobos, 0, {});
	vm.call_dst("?", func, 0, {});
	vm.run()!;
	ValueRc* value_rc = vm.stack[0];
    Value value = *value_rc.value;
	value_rc.free();
	phobos.free();
	func.free();
    return value;
}