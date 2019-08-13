import XCTest

extension Substring {
    mutating func remove(upToAndIncluding idx: Index) {
        self = self[index(after: idx)...]
    }
    
    mutating func parseField() -> Substring {
        assert(!self.isEmpty)
        switch self[startIndex] {
        case "\"":
            removeFirst()
            guard let quoteIdx = index(of: "\"") else {
                fatalError("expected quote") // todo throws
            }
            let result = prefix(upTo: quoteIdx)
            remove(upToAndIncluding: quoteIdx)
            if !isEmpty {
                let comma = removeFirst()
                assert(comma == ",") // todo throws
            }
            return result
            
        default:
            if let commaIdx = index(of: ",") {
                let result = prefix(upTo: commaIdx)
                remove(upToAndIncluding: commaIdx)
                return result
            } else {
                let result = self
                removeAll()
                return result
            }
        }
    }
}

func parse(line: Substring) -> [Substring] {
    var remainder = line
    var result: [Substring] = []
    while !remainder.isEmpty {
        result.append(remainder.parseField())
    }
    return result
}

func parse(lines: String) -> [[Substring]] {
    return lines.split(whereSeparator: { char in
        switch char {
        case "\r", "\n", "\r\n": return true
        default: return false
        }
    }).map { line in
        parse(line: line)
    }
}

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
        CSVTestCase(name: "multiline", input: "one,2,,three\nfour,five", expected: [["one", "2", "", "three"], ["four","five"]]),
//        CSVTestCase(name: "crlf", input: "one,2,,three\r\nfour,five", expected: [["one", "2", "", "three"], ["four","five"]])
        
    ]
    
    func testParse1() {
        for c in cases {
            let result = parse(lines: c.input).map { $0.map(String.init) }
            XCTAssertEqual(result, c.expected, "Case \(c.name) failed")
        }
    }
    
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


