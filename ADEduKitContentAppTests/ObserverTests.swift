//
//  ObserverTests.swift
//  ADEduKitContentAppTests
//
//  Created by Schwarze on 30.01.22.
//

import XCTest
@testable import ADEduKitContentApp

class ObserverTests: XCTestCase {
    func testObserver() throws {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let docs = urls.first
        let obsUrl = docs?.appendingPathComponent("observer_tests.txt")

        let data = "test text".data(using: .utf8)
        try! data?.write(to: obsUrl!)

        let obs = try! Observer(url: obsUrl!)
        obs.start()
        let exp1 = XCTestExpectation(description: "exp1")
        let exp2 = XCTestExpectation(description: "exp2")
        obs.block = {
            exp1.fulfill()
        }
        obs.closeBlock = {
            exp2.fulfill()
        }
        do {
            let fh = try! FileHandle(forWritingTo: obsUrl!)
            defer { try! fh.close() }
            try! fh.seekToEnd()
            try! fh.write(contentsOf: data!)
            print("\(#function): wrote to file")

            let s2 = try! String(contentsOf: obsUrl!)
            print("\(#function): read data: \(s2)")
        }
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0, execute: {
            print("\(#function): calling stop")
            obs.stop()
        })
        self.wait(for: [exp1, exp2], timeout: 2)
    }
}
