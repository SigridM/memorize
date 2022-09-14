import UIKit
import SwiftUI

@resultBuilder
struct ArrayBuilder {
    typealias Component = [Int]
    typealias Expression = Int
    static func buildExpression(_ element: Expression) -> Component {
        return [element]
    }
    static func buildBlock(_ components: Component...) -> Component {
        return Array(components.joined())
    }
}

@ArrayBuilder var builderNumber: [Int] { 10 }
//var manualNumber = ArrayBuilder.buildExpression(10)

print(builderNumber)

@ArrayBuilder var builderBlock: [Int] {
    100
    200
    300
}

print(builderBlock)

var greeting = "Hello, playground"

@ViewBuilder var builderView: TupleView<Button<Text>> {
    Button(Text("test1"), action: {})
    Button(Text("test2"), action: {})

}

