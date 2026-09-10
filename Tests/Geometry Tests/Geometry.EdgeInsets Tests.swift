import Geometry
import Foundation
import Testing

@Test func `Geometry inset is exactly the atom without wrapper conversion`() throws {
    let atom = Inset(top: -1, leading: 2, bottom: 3, trailing: -4)
    let geometry: Geometry<Int, Void>.Insets = atom
    let roundTrip: Inset<2, Int> = geometry
    #expect(roundTrip == atom)
    #expect(geometry.horizontal == -2 && geometry.vertical == 2)
    let other = Inset<2, Int>(all: 5)
    #expect(geometry + other == Inset(top: 4, leading: 7, bottom: 8, trailing: 1))
    let data = try JSONEncoder().encode(geometry)
    #expect(try JSONDecoder().decode(Inset<2, Int>.self, from: data) == atom)
}
