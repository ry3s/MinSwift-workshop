import Foundation
import SwiftSyntax

class Parser: SyntaxVisitor {
    private(set) var tokens: [TokenSyntax] = []
    private var index = 0
    private(set) var currentToken: TokenSyntax!

    // MARK: Practice 1

    override func visit(_ token: TokenSyntax) {
        tokens.append(token)
        print("Parsing \(token.tokenKind)")
    }

    @discardableResult
    func read() -> TokenSyntax {
        currentToken = tokens[index]
        index += 1
        return currentToken 
        //fatalError("Not Implemented")
    }

    func peek(_ n: Int = 0) -> TokenSyntax {
        return tokens[index + n]
        //fatalError("Not Implemented")
    }

    // MARK: Practice 2

    private func extractNumberLiteral(from token: TokenSyntax) -> Double? {
        switch token.tokenKind {
        case .integerLiteral(let str):
            return Double(str)
        case .floatingLiteral(let str):
            return Double(str)
        default:
            return nil
        }

        //fatalError("Not Implemented")
    }

    func parseNumber() -> Node {
        guard let value = extractNumberLiteral(from: currentToken) else {
            fatalError("any number is expected")
        }
        read() // eat literal
        return NumberNode(value: value)
    }
    
    private func extractIdentifier(from token: TokenSyntax) -> String? {
        switch token.tokenKind {
        case .identifier(let str):
            return str
        default:
            return nil
        }
    }
    func parseIdentifierExpression() -> Node {
        guard let identStr = extractIdentifier(from: currentToken) else {
            fatalError("any id is expected")
        }
        read()
        if currentToken.tokenKind == TokenKind.leftParen {
            var callArguments = [CallExpressionNode.Argument]()
            read()
            while true {
                if currentToken.tokenKind == TokenKind.rightParen {
                    break
                } else {
                    guard let callLabel = extractIdentifier(from: currentToken) else {
                        fatalError()
                    }
                    read()
                    guard case .colon = currentToken.tokenKind else {
                        fatalError()
                    }
                    read()
                    guard let callArgument = parseExpression() else {
                        fatalError()
                    }
                    callArguments.append(CallExpressionNode.Argument(label: callLabel, value: callArgument))
                    if currentToken.tokenKind == TokenKind.comma  {
                        read()
                        continue
                    } else {
                        break
                    }
                    
                }
            }
            read()
            return CallExpressionNode(callee: identStr, arguments: callArguments)
        } else {
            return VariableNode(identifier: identStr)
        }
        // fatalError("Not Implemented")
    }

    // MARK: Practice 3

    func extractBinaryOperator(from token: TokenSyntax) -> BinaryExpressionNode.Operator? {
        switch token.tokenKind {
        case .spacedBinaryOperator(let str):
            return BinaryExpressionNode.Operator(rawValue: str)
        default:
            return nil
        }
        // fatalError("Not Implemented")
    }

    private func parseBinaryOperatorRHS(expressionPrecedence: Int, lhs: Node?) -> Node? {
        var currentLHS: Node? = lhs
        while true {
            let binaryOperator = extractBinaryOperator(from: currentToken!)
            let operatorPrecedence = binaryOperator?.precedence ?? -1
            
            // Compare between nextOperator's precedences and current one
            if operatorPrecedence < expressionPrecedence {
                return currentLHS
            }
            
            read() // eat binary operator
            var rhs = parsePrimary()
            if rhs == nil {
                return nil
            }
            
            // If binOperator binds less tightly with RHS than the operator after RHS, let
            // the pending operator take RHS as its LHS.
            let nextPrecedence = extractBinaryOperator(from: currentToken)?.precedence ?? -1
            if (operatorPrecedence < nextPrecedence) {
                // Search next RHS from currentRHS
                // next precedence will be `operatorPrecedence + 1`
                rhs = parseBinaryOperatorRHS(expressionPrecedence: operatorPrecedence + 1, lhs: rhs)
                if rhs == nil {
                    return nil
                }
            }
            
            guard let nonOptionalRHS = rhs else {
                fatalError("rhs must be nonnull")
            }
            
            currentLHS = BinaryExpressionNode(binaryOperator!,
                                              lhs: currentLHS!,
                                              rhs: nonOptionalRHS)
        }
    }

    // MARK: Practice 4

    func parseFunctionDefinitionArgument() -> FunctionNode.Argument {
        guard let identStr = extractIdentifier(from: currentToken) else {
          fatalError("expected function argument")
        }
        read()
        if currentToken.tokenKind == TokenKind.colon {
            read()
        } else {
            fatalError("expected colon")
        }

        guard let typeStr = extractIdentifier(from: currentToken) else {
            fatalError("expected type label")
        }
        read()
        // fatalError("Not Implemented")
        return FunctionNode.Argument.init(label: identStr, variableName: identStr)
    }

    func parseFunctionDefinition() -> Node {
        var functionArguments = [FunctionNode.Argument]()
        guard case .funcKeyword = currentToken.tokenKind else {
            fatalError("required func keyword")
        }
        read()
        guard let functionName = extractIdentifier(from: currentToken) else {
            fatalError("error function name")
        }
        read()
        guard case .leftParen = currentToken.tokenKind else {
            fatalError("required left paren")
        }
        read()
        while true {
            if currentToken.tokenKind == TokenKind.rightParen {
                break
            } else {
                functionArguments.append(parseFunctionDefinitionArgument())
                if currentToken.tokenKind == TokenKind.comma  {
                    read()
                    continue
                } else {
                    break
                }
                
            }
        }
       
        read()
        /*guard case .rightParen = currentToken.tokenKind else {
            fatalError("required right paren")
        }*/
        // read()
        guard case .arrow = currentToken.tokenKind else {
            fatalError("required right arrow")
        }
        read()
        guard let returnType = extractIdentifier(from: currentToken) else {
            fatalError("require return type")
        }
        read()
        guard case .leftBrace = currentToken.tokenKind else {
            fatalError("require left brace")
        }
        read()
        guard let functionBody = parseExpression() else {
            fatalError("error fuction body definition")
        }
        guard case .rightBrace = currentToken.tokenKind else {
            fatalError("require rigt brace")
        }
        read()
        return FunctionNode(name: functionName,
                            arguments: functionArguments,
                            returnType: Type.double,
                            body: functionBody)
        
    }

    // MARK: Practice 7

    func parseIfElse() -> Node {
        guard case .ifKeyword = currentToken.tokenKind else {
            fatalError("require if keyword")
        }
        read()
        let condition = parseExpression()
        guard case .leftBrace = currentToken.tokenKind else {
            fatalError("require left brace")
        }
        read()
        let then = parseExpression()
        guard case .rightBrace = currentToken.tokenKind else {
            fatalError("require right brace")
        }
        guard case .elseKeyword = currentToken.tokenKind else {
            fatalError("")
        }
        read()
        
        return IfElseNode(condition: <#T##Node#>, then: <#T##Node#>, else: <#T##Node?#>)
    }

    // PROBABLY WORKS WELL, TRUST ME

    func parse() -> [Node] {
        var nodes: [Node] = []
        read()
        while true {
            switch currentToken.tokenKind {
            case .eof:
                return nodes
            case .funcKeyword:
                let node = parseFunctionDefinition()
                nodes.append(node)
            default:
                if let node = parseTopLevelExpression() {
                    nodes.append(node)
                    break
                } else {
                    read()
                }
            }
        }
        return nodes
    }

    private func parsePrimary() -> Node? {
        switch currentToken.tokenKind {
        case .identifier:
            return parseIdentifierExpression()
        case .integerLiteral, .floatingLiteral:
            return parseNumber()
        case .leftParen:
            return parseParen()
        case .funcKeyword:
            return parseFunctionDefinition()
        case .returnKeyword:
            return parseReturn()
        case .ifKeyword:
            return parseIfElse()
        case .eof:
            return nil
        default:
            fatalError("Unexpected token \(currentToken.tokenKind) \(currentToken.text)")
        }
        return nil
    }

    func parseExpression() -> Node? {
        guard let lhs = parsePrimary() else {
            return nil
        }
        return parseBinaryOperatorRHS(expressionPrecedence: 0, lhs: lhs)
    }

    private func parseReturn() -> Node {
        guard case .returnKeyword = currentToken.tokenKind else {
            fatalError("returnKeyword is expected but received \(currentToken.tokenKind)")
        }
        read() // eat return
        if let expression = parseExpression() {
            return ReturnNode(body: expression)
        } else {
            // return nothing
            return ReturnNode(body: nil)
        }
    }

    private func parseParen() -> Node? {
        read() // eat (
        guard let v = parseExpression() else {
            return nil
        }

        guard case .rightParen = currentToken.tokenKind else {
                fatalError("expected ')'")
        }
        read() // eat )

        return v
    }

    private func parseTopLevelExpression() -> Node? {
        if let expression = parseExpression() {
            // we treat top level expressions as anonymous functions
            let anonymousPrototype = FunctionNode(name: "main", arguments: [], returnType: .int, body: expression)
            return anonymousPrototype
        }
        return nil
    }
}

private extension BinaryExpressionNode.Operator {
    var precedence: Int {
        switch self {
        case .addition, .subtraction: return 20
        case .multication, .division: return 40
        case .lessThan:
            fatalError("Not Implemented")
        default:
            fatalError("Not Implemented")
        }
    }
}
