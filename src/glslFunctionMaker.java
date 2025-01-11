import java.util.Objects;
import java.util.Stack;


public class glslFunctionMaker {
    public static void main(String[] args) {
        glslFunctionMaker test = new glslFunctionMaker("q--1*((q^3)-1)/(3*q^2)");
    }

    private final Stack<String> sortedTokenStack = new Stack<>();
    private final Stack<String> tokenStack = new Stack<>();
    private final String function;

    public glslFunctionMaker(String _function) {
        function = _function;
        stringToTokenStack();
        operationSorter();
    }

    public String makeCode() {
        Stack<String> calculator = new Stack<>();
        Stack<String> _sortedTokenStack = reverseStack(sortedTokenStack);

        while (!_sortedTokenStack.isEmpty()) {
            String savedA = "", savedB = "";
            if (_sortedTokenStack.peek().charAt(0) != '_') {
                calculator.push(_sortedTokenStack.peek());
                _sortedTokenStack.pop();
            } else {
                savedA = calculator.peek();
                calculator.pop();
                savedB = calculator.peek();
                calculator.pop();
                switch (_sortedTokenStack.peek()) {
                    case "_qmul" -> calculator.push("qmul(" + savedB + "," + savedA + ")");
                    case "_qdiv" -> calculator.push("qdiv(" + savedB + "," + savedA + ")");
                    case "_qpow" -> calculator.push("qpow(" + savedB + "," + savedA + ")");
                    case "_minus" -> calculator.push(savedB + "-" + savedA);
                    case "_plus" -> calculator.push(savedB + "+" + savedA);
                }
                _sortedTokenStack.pop();
            }
        }
        String glslFinal = "";
        calculator = reverseStack(calculator);
        while (!calculator.isEmpty()) {
            glslFinal = glslFinal + calculator.peek();
            calculator.pop();
        }
        return "vec4 javaFunction(vec4 q) {  return " + glslFinal + ";}";
    }



    private void operationSorter() {
        Stack<String> opStack = new Stack<>();
        Stack<String> _inputStack = reverseStack((Stack<String>) tokenStack.clone());

        while (!_inputStack.isEmpty()) {
            if (_inputStack.peek().charAt(0) != '_') {
                sortedTokenStack.push(_inputStack.peek());
                _inputStack.pop();
            } else if (_inputStack.peek().charAt(0) == '_') {
                if (Objects.equals(_inputStack.peek(), "_(")) {
                    opStack.push(_inputStack.peek());
                    _inputStack.pop();
                } else if (Objects.equals(_inputStack.peek(), "_)")) {
                    while (!Objects.equals(opStack.peek(), "_(")) {
                        sortedTokenStack.push(opStack.peek());
                        opStack.pop();
                    }
                    _inputStack.pop();
                    opStack.pop();
                } else {
                    while (!opStack.isEmpty() && ((operatorPrecedence(opStack) > operatorPrecedence(_inputStack)) || (operatorPrecedence(opStack) == operatorPrecedence(_inputStack) && Objects.equals(_inputStack.peek(), "_qpow")))) {
                        sortedTokenStack.push(opStack.peek());
                        opStack.pop();
                    }
                    opStack.push(_inputStack.peek());
                    _inputStack.pop();
                }
            }
        }
        while (!opStack.isEmpty()) {
            sortedTokenStack.push(opStack.peek());
            opStack.pop();
        }
    }


    private void stringToTokenStack() {
        String functionCopy = function + "$";
        boolean isPower = false;
        String longToken = "";

        while (!functionCopy.isEmpty()) {

            if (functionCopy.charAt(0) >= '0' && functionCopy.charAt(0) <= '9' || functionCopy.charAt(0) == '.' || functionCopy.charAt(0) == 't') {
                if (functionCopy.charAt(0) == 't') {
                    longToken = "timeSin";
                    functionCopy = functionCopy.substring(1);
                }
                while (!functionCopy.isEmpty() && (functionCopy.charAt(0) >= '0' && functionCopy.charAt(0) <= '9' || functionCopy.charAt(0) == '.')) {
                    longToken = longToken + functionCopy.charAt(0);
                    functionCopy = functionCopy.substring(1);
                }
                if (!isPower) {
                    longToken = "vec4(" + longToken + ",0,0,0)";
                }
                tokenStack.push(longToken);
                longToken = "";
            } else if (functionCopy.startsWith("quant(")) {
                functionCopy = functionCopy.substring(6);
                longToken = "vec4(";
                while (functionCopy.charAt(0) != ')') {
                    if (functionCopy.charAt(0) == 't') {
                        longToken = longToken + "timeSin";
                    } else {
                        longToken = longToken + functionCopy.charAt(0);
                    }
                    functionCopy = functionCopy.substring(1);
                }
                longToken = longToken + ")";
                tokenStack.push(longToken);
                if (!functionCopy.isEmpty()) functionCopy = functionCopy.substring(1);
            } else {
                isPower = false;
                longToken = "";
                if (functionCopy.charAt(0) == '-' && (tokenStack.isEmpty() || (tokenStack.peek().charAt(0) == '_' && tokenStack.peek().length() > 2))) {
                    longToken = "-";
                } else if (functionCopy.charAt(0) >= 'q') {
                    tokenStack.push("q");
                } else switch (functionCopy.charAt(0)) {
                    case '+' -> tokenStack.push("_plus");
                    case '-' -> tokenStack.push("_minus");
                    case '*' -> tokenStack.push("_qmul");
                    case '/' -> tokenStack.push("_qdiv");
                    case '(' -> tokenStack.push("_(");
                    case ')' -> tokenStack.push("_)");
                    case '^' -> {
                        tokenStack.push("_qpow");
                        isPower = true;
                    }
                }
                functionCopy = functionCopy.substring(1);
            }
        }
    }

    private int operatorPrecedence(Stack<String> stack) {
        int operatorPrecedence = 0;
        switch (stack.peek()) {
            case "_plus", "_minus" -> operatorPrecedence = 2;
            case "_qmul", "_qdiv" -> operatorPrecedence = 3;
            case "_qpow" -> operatorPrecedence = 5;
            case "_(" -> operatorPrecedence = 1;
            case "_)" -> operatorPrecedence = 10;
        }
        return operatorPrecedence;
    }

    private static Stack<String> reverseStack(Stack<String> notReversed) {
        Stack<String> reverse = new Stack<>();
        while (!notReversed.isEmpty()) {
            reverse.push(notReversed.peek());
            notReversed.pop();
        }
        return reverse;
    }
}