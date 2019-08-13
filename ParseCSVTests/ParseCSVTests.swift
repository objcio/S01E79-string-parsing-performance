import XCTest

extension String {
    func parseAlt() -> [[String]] {
        var result: [[String]] = [[]]
        var currentField = "".unicodeScalars
        var inQuotes = false
        
        @inline(__always) func flush() {
            result[result.endIndex-1].append(String(currentField))
            currentField.removeAll()
        }
        
        for c in self.unicodeScalars {
            switch (c, inQuotes) {
            case (",", false):
                flush()
            case ("\n", false):
                flush()
                result.append([])
            case ("\"", _):
                inQuotes = !inQuotes
            default:
                currentField.append(c)
            }
        }
        flush()
        return result
    }
}

struct CSVTestCase {
    var name: String
    var input: String
    var expected: [[String]]
}

class ParseCSVTests: XCTestCase {
    let cases: [CSVTestCase] = [
        CSVTestCase(name: "line", input: "one,2,,three", expected: [["one", "2", "", "three"]]),
        CSVTestCase(name: "multipleLines", input: "one,2,,three\nfive,six,\"hello,q\"", expected: [["one", "2", "", "three"], ["five", "six", "hello,q"]]),
        CSVTestCase(name: "quotes", input: "one,\"qu,ote\",2,,three", expected: [["one", "qu,ote", "2", "", "three"]]),        
    ]
        
    func testParseAlt() {
        for c in cases {
            let result = c.input.parseAlt()
            XCTAssertEqual(result, c.expected, "Case \(c.name) failed")
        }
    }
    
    func testPerformance() {
        let bundle = Bundle(for: ParseCSVTests.self)
        let url = bundle.url(forResource: "small", withExtension: "txt")!
        let data = try! Data(contentsOf: url)
        let string = String(data: data, encoding: .isoLatin1)! + ""

        measure {
            _ = string.parseAlt()
        }
    }
}





















func ==<A: Equatable>(lhs: [[A]], rhs: [[A]]) -> Bool {
    guard lhs.count == rhs.count else { return false }
    for (l,r) in zip(lhs,rhs) {
        guard l == r else { return false }
    }
    return true
}


func XCTAssertEqual<T>(_ lhs: [[T]], _ rhs: [[T]], file: StaticString = #file, line: UInt = #line) where T : Equatable {
    XCTAssert(lhs == rhs, "Expected \(lhs) and \(rhs) to be equal.", file: file, line: line)
}


