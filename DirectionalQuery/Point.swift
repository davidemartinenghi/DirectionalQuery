//
//  Point.swift
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 10/11/2016.
//  Copyright © 2016 Davide Martinenghi. All rights reserved.
//

import Foundation

typealias IdType = Int

struct Point {
    static var counter = 0
    
    var values: [Double]
    var sum = 0.0
    var max: Double {
        return values.max() ?? 0.0
    }
    var min: Double {
        return values.min() ?? 1.0
    }
    let id: IdType
    init(values: [Double]) {
        self.init(id: Point.counter, values: values)
        Point.counter += 1
    }
    init(inversePercentages: [Double]) {
        self.init(id: Point.counter, inversePercentages: inversePercentages)
        Point.counter += 1
    }
    init(id: IdType, values: [Double]) {
        self.id = id
        self.values = values
        sum = values.reduce(0.0) { $0 + $1 }
    }
    init(id: IdType, inversePercentages: [Double]) {
        self.id = id
        values = []
        sum = 0.0
        for value in inversePercentages {
            let invertedValue = (100.0 - value) / 100.0
            values.append(invertedValue)
            sum += invertedValue
        }
    }

    subscript(i: Int) -> Double { return values[i] }
    func dominates(point: Point) -> Bool {
        var hasStrict = false
        for i in 0..<values.count {
            if self[i] > point[i] {
                return false
            } else if self[i] < point[i] {
                hasStrict = true
            }
        }
        return hasStrict
    }
    func valueBy(innerPoint: Point, p: Double) -> Double {
        var total = 0.0
        for i in 0..<values.count {
            total += pow(values[i],p) * innerPoint[i]
        }
        return total
    }
}
extension Point: CustomStringConvertible {
    var pointDescription: String {
        return "\(id): " + description
    }
    var mathematica: String {
        return "{ " + csvFullPrecision + " }"
    }
    var csvwithid: String {
        var output = "\(id), "
        for value in values {
            output += String(format: "%.6f", value) + ", "
        }
        if output.count > 2 {
            return String(output[..<output.index(output.endIndex, offsetBy: -2)])
        }
        return output
    }
    var csv: String {
        var output = ""
        for value in values {
            output += String(format: "%.6f", value) + ", "
        }
        if output.count > 2 {
            return String(output[..<output.index(output.endIndex, offsetBy: -2)])
        }
        return output
    }
    var csvFullPrecision: String {
        var output = ""
        for value in values {
            output += "\(value), "
        }
        if output.count > 2 {
            return String(output[..<output.index(output.endIndex, offsetBy: -2)])
        }
        return output
    }
    var description: String {
        return "[" + csv + "]"
    }
}

extension Point: Equatable {}

extension Point: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(values)
    }
}

func == (lhs: Point, rhs: Point) -> Bool {
    for i in 0..<lhs.values.count {
        if lhs[i] != rhs[i] {
            return false
        }
    }
    return true
}

// This is a collection of points interpreted as vertices of the polytope as in Theorem 5
extension Collection where Iterator.Element == Int {
    func isDominated(point: Point) -> Bool {
        return false
    }
}

extension Point {
    static func random(dimensions: Int) -> Point {
        var values = [Double]()
        for _ in 1...dimensions {
            values.append(Double(arc4random_uniform(1_000_000))/1_000_000.0)
        }
        return Point(values: values)
    }
    @inline(__always) func isOrderedBefore(otherPoint: Point, weights: Point) -> Bool {
        let total = zip(values, weights.values).reduce(0.0) { $0 + $1.0 * $1.1 }
        let otherTotal = zip(otherPoint.values, weights.values).reduce(0.0) { $0 + $1.0 * $1.1 }
        return total < otherTotal
    }
    @inline(__always) func isOrderedBeforeOrSame(otherPoint: Point, weights: Point) -> Bool {
        let total = zip(values, weights.values).reduce(0.0) { $0 + $1.0 * $1.1 }
        let otherTotal = zip(otherPoint.values, weights.values).reduce(0.0) { $0 + $1.0 * $1.1 }
        return total <= otherTotal
    }
}

extension Array where Element == Point {
    var mathematicaPolygon: String {
        return "Polygon[{ " + map { $0.mathematica }.joined(separator: ", ") + " }]"
    }
}
