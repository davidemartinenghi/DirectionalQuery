//
//  SFS.swift
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 10/11/2016.
//  Copyright © 2016 Davide Martinenghi. All rights reserved.
//

import Foundation

struct SkyCalculator {
    let dataSet: DataSet
    var window = DataSet(points: [])
    var skyline: DataSet?
    var topK: DataSet?
    var currentMethod = ""
    var dominanceComparisons = 0
    var sortedDataSet = DataSet(points: [])
    var skyTime = 0.0
    var k = 1
    var gridResistanceMap = [Point:Double]()
    var exclusiveVolumeMap = [Point:Double]()
    var dimensions: Int { return dataSet.dimensions }
    var sumOfSquaresOfWeights = 0.0
    
    //MARK: Skyline variants
    mutating func computeSkyline() {
        let start = Date()
        dominanceComparisons = 0
        sortData()
        window = DataSet(points: [])
        
        externalLoop:
        for point in sortedDataSet.points {
            
            // explicit loop to add counting
            for p in window.points {
                dominanceComparisons += 1
                if p.dominates(point: point) {
                    continue externalLoop
                }
            }
            window.add(point: point)

        }
        skyline = window
        skyTime = Date().timeIntervalSince(start)
//        print("Skyline in: " + String(format: "%.2f", skyTime) + " seconds, data points: \(dataSet.points.count), sky points: \(window.points.count), dominance tests: \(dominanceComparisons)")
    }
}

//MARK: Sorting and vertices
extension SkyCalculator {
    // computes the vertices of the polytope and sorts the dataset by the centroid of the polytope
    mutating func sortData() {
//        let start2 = Date()
        // sorting the dataset by the inner point
        sortedDataSet.points = dataSet.points.sorted(by: { (p1: Point, p2: Point) -> Bool in
            for i in 0..<dimensions {
                if p1.values[i] < p2.values[i] {
                    return true
                } else if p1.values[i] > p2.values[i] {
                    return false
                }
            }
            return false
        })
    }
}

//MARK: Ranking
extension SkyCalculator {
    mutating func computeTopK(k: Int, weights: [Double]) -> [Point] {
        sortedDataSet.points = dataSet.points.sorted(by: { (p1: Point, p2: Point) -> Bool in
            let s1 = zip(weights,p1.values).map { $0.0 * $0.1 }.reduce(0.0,+)
            let s2 = zip(weights,p2.values).map { $0.0 * $0.1 }.reduce(0.0,+)
            return s1 < s2
        })
        return [Point](sortedDataSet.points.prefix(upTo: k))
    }
    mutating func computeDirKViaHeap(k: Int, weights: [Double], beta: Double = 2.0/3.0) -> [Point] {
        let dc = DirComparator(weights: weights, beta: beta)

        var queue = QueueK(capacity: k, points: []) { p1, p2 in
            return dc.compareWithDir(p1: p1, p2: p2)
        }
        for point in dataSet.points {
            queue.insert(point: point)
        }
        return queue.heap.elements.sorted { p1, p2 in
            return dc.compareWithDir(p1: p1, p2: p2)
        }
    }
    func compareLinear(p1: Point, p2: Point, weights: [Double]) -> Bool {
        let s1 = zip(weights,p1.values).map { $0.0 * $0.1 }.reduce(0.0,+)
        let s2 = zip(weights,p2.values).map { $0.0 * $0.1 }.reduce(0.0,+)
        return s1 < s2
    }
    func computeTopKViaHeap(k: Int, weights: [Double]) -> [Point] {
        var queue = QueueK(capacity: k, points: []) { p1, p2 in
            return compareLinear(p1: p1, p2: p2, weights: weights)
        }
        for point in dataSet.points {
            queue.insert(point: point)
        }
        return queue.heap.elements.sorted { p1, p2 in
            return compareLinear(p1: p1, p2: p2, weights: weights)
        }
    }

}

struct DirComparator {
    var weights: [Double]
    var invertedWeights: [Double]
    var beta: Double
    var sumOfSquaresOfWeights: Double
    
    init(weights: [Double], beta: Double) {
        self.weights = weights
        self.beta = beta
        self.invertedWeights = weights.map { 1.0/$0 }
        self.sumOfSquaresOfWeights = invertedWeights.map { $0 * $0 }.reduce(0.0,+)
    }
    func compareWithDir(p1: Point, p2: Point) -> Bool {
        return score(point: p1) < score(point: p2)
    }
    func score(point: Point) -> Double {
        let s1 = zip(weights,point.values).map { $0.0 * $0.1 }.reduce(0.0,+)
        let l1 = distFromPrefLine(values: point.values)
        let f1 = beta * s1 + (1-beta) * l1
        return f1
    }
    
    func distFromPrefLine(values: [Double]) -> Double {
        var tot = 0.0
        let s = zip(invertedWeights,values).map { $0.0 * $0.1 }.reduce(0.0,+)
        let w2 = sumOfSquaresOfWeights
        for i in 0..<values.count {
            let contrib = values[i] - invertedWeights[i] * s / w2
            tot += contrib * contrib
        }
        return sqrt(tot)
    }
}

//MARK: Indicators
extension SkyCalculator {
    mutating func computeExclusiveVolume() {
        guard let sky = skyline else { return }
        if dimensions == 2 {
            let sortedPoints = sky.points.sorted { $0.values[0] < $1.values[0] }
            for i in 0..<sortedPoints.count {
                let point = sortedPoints[i]
                let xNext = (i == sortedPoints.count-1) ? 1.0 : sortedPoints[i+1].values[0]
                let yPrev = (i == 0) ? 1.0 : sortedPoints[i-1].values[1]
                let evol = (xNext - point.values[0]) * (yPrev - point.values[1])
                exclusiveVolumeMap[point] = evol
            }
        } else {
            let samples = 100000
            for _ in 1...samples {
                let randomPoint = Point.random(dimensions: dimensions)
                let dominance = sky.points.map { $0.dominates(point: randomPoint) }
                let dominanceCount = dominance.reduce(0) {
                    $0 + ($1 ? 1 : 0)
                }
                if dominanceCount == 1 {
                    if let index = dominance.firstIndex(of: true) {
                        let point = sky.points[index]
                        exclusiveVolumeMap[point] = (exclusiveVolumeMap[point] ?? 0.0) + 1.0 / Double(samples)
                    }
                }
            }
        }
    }
    
    mutating func computeGridResistance() {
        guard let points = skyline?.points else { return }
        for grid in (2...250).reversed() {
            let gridProjections = points.map {
                Point(id: $0.id, values: $0.values.map {
                    floor($0 * Double(grid)) / Double(grid)
                })
            }
            let gpDataset = DataSet(points: gridProjections)
            var algorithm = SkyCalculator(dataSet: gpDataset)
            algorithm.computeSkyline()
            guard let gpSky = algorithm.skyline else { return }
            let gpSkyIds = gpSky.points.map { $0.id }
            for point in points {
                if !gpSkyIds.contains(point.id) {
                    if gridResistanceMap[point] == nil {
                        gridResistanceMap[point] = 1.0/Double(grid)
                    }
                }
            }
        }
    }
}
