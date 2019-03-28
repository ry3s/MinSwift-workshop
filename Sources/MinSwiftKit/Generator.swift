import Foundation
import LLVM

@discardableResult
func generateIRValue(from node: Node, with context: BuildContext) -> IRValue {
    switch node {
    case let numberNode as NumberNode:
        return Generator<NumberNode>(node: numberNode).generate(with: context)
    case let binaryExpressionNode as BinaryExpressionNode:
        return Generator<BinaryExpressionNode>(node: binaryExpressionNode).generate(with: context)
    case let variableNode as VariableNode:
        return Generator<VariableNode>(node: variableNode).generate(with: context)
    case let functionNode as FunctionNode:
        return Generator<FunctionNode>(node: functionNode).generate(with: context)
    case let callExpressionNode as CallExpressionNode:
        return Generator<CallExpressionNode>(node: callExpressionNode).generate(with: context)
    case let ifElseNode as IfElseNode:
        return Generator<IfElseNode>(node: ifElseNode).generate(with: context)
    case let returnNode as ReturnNode:
        return Generator<ReturnNode>(node: returnNode).generate(with: context)
    default:
        fatalError("Unknown node type \(type(of: node))")
    }
}

private protocol GeneratorProtocol {
    associatedtype NodeType: Node
    var node: NodeType { get }
    func generate(with: BuildContext) -> IRValue
    init(node: NodeType)
}

private struct Generator<NodeType: Node>: GeneratorProtocol {
    func generate(with context: BuildContext) -> IRValue {
        fatalError("Not implemented")
    }

    let node: NodeType
    init(node: NodeType) {
        self.node = node
    }
}

// MARK: Practice 6

extension Generator where NodeType == NumberNode {
    func generate(with context: BuildContext) -> IRValue {
        return FloatType.double.constant(node.value)
        // fatalError("Not Implemented")
    }
}

extension Generator where NodeType == VariableNode {
    func generate(with context: BuildContext) -> IRValue {
        guard let variable = context.namedValues[node.identifier] else {
            fatalError()
        }
        return variable
        // fatalError("Not Implemented")
    }
}

extension Generator where NodeType == BinaryExpressionNode {
    func generate(with context: BuildContext) -> IRValue {
        let LHS = generateIRValue(from: node.lhs, with: context)
        let RHS = generateIRValue(from: node.rhs, with: context)
        switch node.operator {
        case .addition:
            return context.builder.buildAdd(LHS, RHS)
        case .subtraction:
            return context.builder.buildSub(LHS, RHS)
        case .multication:
            return context.builder.buildMul(LHS, RHS)
        case .division:
            return context.builder.buildDiv(LHS,RHS)
        case .lessThan:
            fatalError("Not Implemented")
        default:
            fatalError("Not implemented")
        }
        
    }
}

extension Generator where NodeType == FunctionNode {
    func generate(with context: BuildContext) -> IRValue {
        let argumentTypes = [IRType](repeating: FloatType.double, count: node.arguments.count)
        let returnType: IRType = FloatType.double
        let functionType = FunctionType(argTypes: argumentTypes,
                                        returnType: returnType)
        let function = context.builder.addFunction(node.name, type: functionType)
        
        let entryBasicBlock = function.appendBasicBlock(named: "entry")
        context.builder.positionAtEnd(of: entryBasicBlock)
        
        context.namedValues.removeAll()
        for i in 0..<node.arguments.count {
            context.namedValues[node.arguments[i].variableName] = function.parameters[i]
        }


        let functionBody: IRValue = generateIRValue(from: node.body, with: context)
        context.builder.buildRet(functionBody)
        return functionBody
        // fatalError("Not Implemented")
    }
}

extension Generator where NodeType == CallExpressionNode {
    func generate(with context: BuildContext) -> IRValue {
        let function = context.module.function(named: node.callee)!
        let arguments: [IRValue] = node.arguments.map({generateIRValue(from: $0.value, with: context)})
        return context.builder.buildCall(function, args: arguments, name: "calltmp")
        // fatalError("Not Implemented")
    }
}

extension Generator where NodeType == IfElseNode {
    func generate(with context: BuildContext) -> IRValue {
        fatalError("Not Implemented")
    }
}

extension Generator where NodeType == ReturnNode {
    func generate(with context: BuildContext) -> IRValue {
        if let body = node.body {
            let returnValue = MinSwiftKit.generateIRValue(from: body, with: context)
            return returnValue
        } else {
            return VoidType().null()
        }
    }
}
