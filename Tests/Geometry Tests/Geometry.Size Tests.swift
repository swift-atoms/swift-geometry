import Geometry
import Testing

@Suite
struct `Size behavior before atom migration` {
    @Test
    func `Named dimensions preserve width height and depth`() {
        let value = Geometry<Int, Void>.Size<3>(width: 2, height: 3, depth: 4)
        #expect(value.width.underlying == 2)
        #expect(value.height.underlying == 3)
        #expect(value.depth == 4)
        #expect(value[0] == 2)
        #expect(value[2] == 4)
    }

    @Test
    func `Mapping transforms each dimension in order`() {
        let value = Geometry<Int, Void>.Size<2>(width: 2, height: 3)
        var visited: [Int] = []
        let mapped = value.map { scalar in
            visited.append(scalar)
            return Double(scalar)
        }
        let result: Geometry<Double, Void>.Size<2> = mapped
        #expect(visited == [2, 3])
        #expect(result.width.underlying == 2)
        #expect(result.height.underlying == 3)
    }
}

@Suite struct `Legacy signed size storage delegation` {
    @Test func `empty mapping never evaluates a scalar`() {
        let empty = Geometry<Int, Void>.Size<0>([])
        var visits = 0
        let result = empty.map { value in visits += 1; return String(value) }
        #expect(result.dimensions.count == 0)
        #expect(visits == 0)
    }

    @Test func `signed arithmetic and frame wrapper semantics remain`() {
        let value = Geometry<Int, Void>.Size<2>([-2, 3])
        let other = Geometry<Int, Void>.Size<2>([4, 5])
        #expect(value + other == Geometry<Int, Void>.Size<2>([2, 8]))
        #expect(value - other == Geometry<Int, Void>.Size<2>([-6, -2]))
        var copy = value
        copy.dimensions[0] = 9
        #expect(value[0] == -2 && copy[0] == 9)
        #expect(Set([value, value, copy]).count == 2)
    }
}

import Foundation

@Test func `legacy size coding delegates exact dimension to Vector`() throws {
    typealias S = Geometry<Int, Void>.Size<2>
    let size = S([-2, 3])
    let data = try JSONEncoder().encode(size)
    #expect(String(decoding: data, as: UTF8.self) == "[-2,3]")
    #expect(try JSONDecoder().decode(S.self, from: data) == size)
    for json in ["[]", "[1]", "[1,2,3]", "[1,\"x\"]"] {
        #expect(throws: DecodingError.self) { try JSONDecoder().decode(S.self, from: Data(json.utf8)) }
    }
    let empty = try JSONDecoder().decode(Geometry<Int, Void>.Size<0>.self, from: Data("[]".utf8))
    #expect(empty.dimensions.count == 0)
}
