//
//  CSVHandler
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 10/11/2016.
//  Copyright © 2016 Davide Martinenghi. All rights reserved.
//

import Foundation

struct CSVHandler {
    func saveCsv(dataSet: DataSet, attributes: [String], fileName: String, ids: Bool = true) {
        guard let _ = try? "".write(toFile: fileName, atomically: true, encoding: .utf8) else {
            print("Error creating \(fileName)")
            return
        }
        //Check if file exists
        if let fileHandle = FileHandle(forWritingAtPath: fileName) {
            //Append to file
            fileHandle.seekToEndOfFile()
            let firstLine = (ids ? "id" : "") + (attributes.isEmpty ? "" : ",") + attributes.joined(separator: ",") + "\n"
            fileHandle.write(firstLine.data(using: .utf8)!)
            fileHandle.seekToEndOfFile()
            if attributes.isEmpty {
                let string = dataSet.points.map { "\($0.id)" }.joined(separator: "\n")
                fileHandle.write(string.data(using: .utf8)!)
            } else {
                if ids {
                    fileHandle.write(dataSet.csvIds.data(using: .utf8)!)
                } else {
                    fileHandle.write(dataSet.csv.data(using: .utf8)!)
                }
            }
        }
    }
    func loadAsMap(from path: String) -> [[String:String]] {
        if let aStreamReader = StreamReader(path: path) {
            defer {
                aStreamReader.close()
            }
            guard let firstLine = aStreamReader.nextLine() else { return [] }
            let attributeNames = firstLine.components(separatedBy: ",")
                .map { $0.trimmingCharacters(in: .whitespaces) }
            
            var table = [[String:String]]()
            while let line = aStreamReader.nextLine() {
                if line == "" { continue }
                let values = line.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespaces) }
                
                var row = [String:String]()
                for j in 0..<values.count {
                    row[attributeNames[j]] = values[j]
                }
                table.append(row)
            }
            return table
        }
        return []
    }
    
    func dataSet(from map: [[String:String]], with attributes: [String], skipIfWrong: Bool = true) -> DataSet {
        var i = 1
        var points = [Point]()
        for row in map {
            var toSkip = false
            var values = [Double]()
            for attribute in attributes {
                if let value = Double(row[attribute] ?? "") {
                    values.append(value)
                } else {
                    print("Wrong value in \(row) for \(attribute)")
                    if skipIfWrong {
                        toSkip = true
                    } else {
                        return DataSet(points: [])
                    }
                }
            }
            let point = Point(id: i, values: values)
            if !toSkip {
                points.append(point)
            }
            i += 1
        }
        return DataSet(points: points)
    }
}
