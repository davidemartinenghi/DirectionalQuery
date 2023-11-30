//
//  DataSet.swift
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 10/11/2016.
//  Copyright © 2016 Davide Martinenghi. All rights reserved.
//

import Foundation

struct DataSet {
    var points: [Point]
    var name = ""
    mutating func removeDominated(by point: Point) {
        // removing dominated points from the data set
        for i in (0..<points.count).reversed() {
            if point.dominates(point: points[i]) {
                points.remove(at: i)
            }
        }
    }
    mutating func add(point: Point) {
        points.append(point)
    }
    func dominates(point: Point) -> Bool {
        for p in points {
            if p.dominates(point: point) {
                return true
            }
        }
        return false
    }
    var dimensions: Int {
        if points.isEmpty { return 0 }
        return points[0].values.count
    }
}

extension DataSet {
    func noDuplicates() -> DataSet {
        var used = Set<Point>()
        var newPoints = [Point]()
        for j in 0..<points.count {
            let point = points[j]
            if !used.contains(point) {
                newPoints.append(point)
                used.insert(point)
            }
        }
        return DataSet(points: newPoints, name: name)
    }
    func inverted() -> DataSet {
        var newPoints = [Point]()
        var maxima: [Double] = []
        for i in 0..<dimensions {
            let maximum = points.map { $0.values[i] }.max() ?? 0.0
            maxima.append(maximum)
        }
        for j in 0..<points.count {
            var newValues: [Double] = []
            for i in 0..<dimensions {
                newValues.append(maxima[i] - points[j].values[i])
            }
            let point = Point(id: points[j].id, values: newValues)
            newPoints.append(point)
        }
        return DataSet(points: newPoints, name: name)
    }
    func normalized() -> DataSet {
        var newPoints = [Point]()
        var maxima: [Double] = []
        for i in 0..<dimensions {
            let maximum = points.map { $0.values[i] }.max() ?? 0.0
            maxima.append(maximum)
        }
        for j in 0..<points.count {
            var newValues: [Double] = []
            for i in 0..<dimensions {
                newValues.append(points[j].values[i] / maxima[i])
            }
            let point = Point(id: points[j].id, values: newValues)
            newPoints.append(point)
        }
        return DataSet(points: newPoints, name: name)
    }
}
extension DataSet: CustomStringConvertible {
    init(points: [Point]) {
        self.points = points
        self.name = ""
    }
    var description: String {
        var output = "["
        for point in points {
            output += "\(point.pointDescription), "
        }
        if output.count > 2 {
            return String(output[..<output.index(output.endIndex, offsetBy: -2)]) + "]"
        }
        return name + " = " + output + "]"
    }
    var csv: String {
        var output = ""
        for point in points {
            output += "\(point.csv)\n"
        }
        return output
    }
    var csvIds: String {
        var output = ""
        for point in points {
            output += "\(point.id),\(point.csv)\n"
        }
        return output
    }

    var mathematica: String {
        var output = "{"
        for point in points {
            output += "{\(point.csv)},"
        }
        output.removeLast()
        output += "}"
        return output
    }

}

