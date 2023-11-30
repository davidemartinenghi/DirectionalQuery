//
//  main.swift
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 27/10/23.
//

import Foundation

fileprivate let datasetDir = "~/cleanData"
fileprivate let allKs = [1,5,10,50,100,500,1000]
fileprivate let allNs = [10000,50000,100000,500000,1000000,5000000,10000000]
fileprivate let allDs = [2,3,4,5,6]
fileprivate let allBetas = [1.0/3,0.5,2.0/3,1.0]
fileprivate let defaultK = 10
fileprivate let defaultN = 1000000
fileprivate let defaultD = 3
fileprivate let defaultBeta = 2.0/3.0

experiment(name: "anti2dWithId", attributes: ["x", "y"], ks: allKs, betas: allBetas)
experiment(name: "NBAstats2WithId", attributes: ["3PM", "OREB"], ks: allKs, betas: allBetas)
experiment(name: "NBAstats3WithId", attributes: ["3PM", "OREB", "GP"], ks: allKs, betas: allBetas)
experiment(name: "householdWithId", attributes: ["A", "B", "C"], ks: allKs, betas: [2.0/3,1.0])
experiment(name: "empWithId", attributes: ["x1", "x2", "x3"], ks: allKs, betas: [2.0/3,1.0])
syntheticExperiment(ns: allNs, ds: [defaultD], ks: [defaultK], betas: allBetas)
syntheticExperiment(ns: [defaultN], ds: [defaultD], ks: allKs, betas: allBetas)
syntheticExperiment(ns: [defaultN], ds: allDs, ks: [defaultK], betas: allBetas)

extension String {
    func padded(length: Int) -> String {
        let len = length-self.count
        return String(repeating: " ", count: len < 0 ? 0 : len) + self
    }
}

func experiment(name: String, attributes: [String], ks: [Int], betas: [Double]) {
    let fileName = NSString(string: "\(datasetDir)/\(name).csv").expandingTildeInPath
    let runs = 100
    let start = Date()
    let dimensions = attributes.count
    let weightRuns = randomWeights(dimensions: dimensions, runs: runs)
    let csvHandler = CSVHandler()
    let table = csvHandler.loadAsMap(from: fileName)
    let dataSet = csvHandler.dataSet(from: table, with: attributes)
    var algorithm = SkyCalculator(dataSet: dataSet)
    algorithm.computeSkyline()
    guard let sky = algorithm.skyline else { return }
    algorithm.computeExclusiveVolume()
    algorithm.computeGridResistance()
    let skyIds = Set(sky.points.map { $0.id })
    print("--- Experiment on \(name). Size: \(dataSet.points.count). Skyline tuples: \(skyIds.count)")
    print("   k, d,       N,     beta,  avgPrec,   avgRec,  avgDist, cumulRec,     time,cumulEvol,cumulGrid")

    for k in ks {
        var times = [Double]()
        for beta in betas {
            var totalPrecision = 0.0
            var totalRecall = 0.0
            var totalDistance = 0.0
            var cumulativeTopInSky = Set<Int>()
            var totalEvol = 0.0
            var totalGridResistance = 0.0

            for weights in weightRuns {
                let time = Date()
                let topPoints = beta == 1.0 ? algorithm.computeTopKViaHeap(k: k, weights: weights) : algorithm.computeDirKViaHeap(k: k, weights: weights, beta: beta)
                times.append(Date().timeIntervalSince(time))
                let topIds = Set(topPoints.map { $0.id })
                let topInSky = topIds.intersection(skyIds)
                let precision = Double(topInSky.count) / Double(k)
                let recall = Double(topInSky.count) / Double(skyIds.count)
                let dc = DirComparator(weights: weights, beta: beta)
                let distance = topPoints.map { dc.distFromPrefLine(values: $0.values) }
                    .reduce(0.0,+) / Double(topPoints.count)
                let evol = topPoints.filter { topIds.contains($0.id) }
                    .map { algorithm.exclusiveVolumeMap[$0] ?? 0.0 }
                    .reduce(0.0,+)
                let gridReistance = topPoints.filter { topIds.contains($0.id) }
                    .map { algorithm.gridResistanceMap[$0] ?? 0.0 }
                    .reduce(0.0,+)
                totalPrecision += precision
                totalRecall += recall
                totalDistance += distance
                totalEvol += evol
                totalGridResistance += gridReistance
                cumulativeTopInSky.formUnion(topInSky)
            }
            let averagePrecision = totalPrecision / Double(weightRuns.count)
            let averageRecall = totalRecall / Double(weightRuns.count)
            let averageDistance = totalDistance / Double(weightRuns.count)
            let cumulativeRecall = Double(cumulativeTopInSky.count) / Double(skyIds.count)
            let cumulativeTopPointsEvol = sky.points.filter { cumulativeTopInSky.contains($0.id) }
                .map { algorithm.exclusiveVolumeMap[$0] ?? 0.0 }
                .reduce(0.0,+)
            let allPointsEvol = sky.points.filter { skyIds.contains($0.id) }
                .map { algorithm.exclusiveVolumeMap[$0] ?? 0.0 }
                .reduce(0.0,+)
            let cumulativeEvolFraction = cumulativeTopPointsEvol / allPointsEvol
            let cumulativeTopPointsGridResistance = sky.points.filter { cumulativeTopInSky.contains($0.id) }
                .map { algorithm.gridResistanceMap[$0] ?? 0.0 }
                .reduce(0.0,+)
            let allPointsGridResistance = sky.points.filter { skyIds.contains($0.id) }
                .map { algorithm.gridResistanceMap[$0] ?? 0.0 }
                .reduce(0.0,+)
            let cumulativeGridResistanceFraction = cumulativeTopPointsGridResistance / allPointsGridResistance
            let avgTime = times.reduce(0.0,+) / Double(times.count)
            
            print("\(k)".padded(length: 4) + ", " +
                  "\(dimensions)" + ", " +
                  "\(dataSet.points.count)".padded(length: 7) + ", " +
                  String(format: "%.6f", beta) + ", " +
                  String(format: "%.6f", averagePrecision) + ", " +
                  String(format: "%.6f", averageRecall) + ", " +
                  String(format: "%.6f", averageDistance) + ", " +
                  String(format: "%.6f", cumulativeRecall) + ", " +
                  String(format: "%.6f", avgTime) + ", " +
                  String(format: "%.6f", cumulativeEvolFraction) + ", " +
                  String(format: "%.6f", cumulativeGridResistanceFraction))
        }
    }
    let elapsed = Date().timeIntervalSince(start)
    print("experiment finished in \(elapsed) seconds")
}

func syntheticExperiment(ns: [Int], ds: [Int], ks: [Int], betas: [Double]) {
    for dimensions in ds {
        let attributes = {
            var atts = [String]()
            for i in 1...dimensions {
                atts.append("x\(i)")
            }
            return atts
        }()
        for size in ns {
            experiment(name: "synt\(dimensions)A\(size)WithId", attributes: attributes, ks: ks, betas: betas)
        }
    }
}

func randomWeights(dimensions: Int, runs: Int) -> [[Double]] {
    var weightRuns = [[Double]]()
    for _ in 1...runs {
        var weights = [Double]()
        var cumulative = 0.0
        for _ in 1...(dimensions-1) {
            let value = Double.random(in: 0.0...(1-cumulative))
            weights.append(value)
            cumulative += value
        }
        let sum = weights.reduce(0.0,+)
        weights.append(1.0 - sum)
        weightRuns.append(weights)
    }
    return weightRuns
}
