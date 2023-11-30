//
//  QueueK.swift
//  DirectionalQuery
//
//  Created by Davide Martinenghi on 21/04/2017.
//  Copyright © 2017 Davide Martinenghi. All rights reserved.
//

import Foundation

struct QueueK {
    let capacity: Int
    var heap: Heap<Point>
    var isOrderedBefore: (Point, Point) -> Bool
    
    init(capacity: Int, points: [Point], isOrderedBefore: @escaping (Point, Point) -> Bool) {
        self.capacity = capacity
        self.heap = Heap<Point>(array: points) { p1,p2 in !isOrderedBefore(p1, p2) }
        self.isOrderedBefore = isOrderedBefore
    }
    func canInsert(point: Point) -> Bool {
        if let last = heap.peek() {
            return heap.count < capacity || isOrderedBefore(point, last)
        }
        return capacity > 0
    }
    mutating func insert(point: Point) {
        if canInsert(point: point) {
            heap.insert(point)
            if heap.count > capacity {
                heap.remove()
            }
        }
    }
}
