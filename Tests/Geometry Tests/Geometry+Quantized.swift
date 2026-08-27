import Dimension
import Geometry
import Numeric
import Tagged
import Tagged_Standard_Library_Integration
import Testing

private enum TestSpace: Numeric.Quantized {}

extension TestSpace {
    typealias Scalar = Double
    static var quantum: Double { 0.01 }
}

private typealias QGeometry = Geometry<Double, TestSpace>

@Suite
struct `Geometry+Quantized` {

    @Suite
    struct `Rectangle` {

        @Test
        func `computed corners are quantized`() {
            let rect = QGeometry.Rectangle(
                x: .init(84.0),
                y: .init(100.0),
                width: .init(65.4),
                height: .init(43.6)
            )

            #expect(rect.llx.ticks == 8400)
            #expect(rect.urx.ticks == 14940)
            #expect(rect.lly.ticks == 10000)
            #expect(rect.ury.ticks == 14360)
        }

        @Test
        func `adjacent rectangles align exactly`() {
            let startY: QGeometry.Y = .init(84.0)
            let rowHeight: QGeometry.Height = .init(21.8)

            let row1 = QGeometry.Rectangle(
                x: .init(0),
                y: startY,
                width: .init(100),
                height: rowHeight
            )
            let row2 = QGeometry.Rectangle(
                x: .init(0),
                y: row1.ury,
                width: .init(100),
                height: rowHeight
            )
            let row3 = QGeometry.Rectangle(
                x: .init(0),
                y: row2.ury,
                width: .init(100),
                height: rowHeight
            )

            let spanHeight: QGeometry.Height = .init(65.4)
            let span = QGeometry.Rectangle(
                x: .init(0),
                y: startY,
                width: .init(100),
                height: spanHeight
            )

            #expect(row3.ury.ticks == span.ury.ticks)
        }

        @Test
        func `accumulated row heights match span`() {
            let startY: QGeometry.Y = .init(84.0)
            let rowHeight: QGeometry.Height = .init(21.8)

            let row1 = QGeometry.Rectangle(
                x: .init(0),
                y: startY,
                width: .init(100),
                height: rowHeight
            )
            let row2 = QGeometry.Rectangle(
                x: .init(0),
                y: row1.ury,
                width: .init(100),
                height: rowHeight
            )
            let row3 = QGeometry.Rectangle(
                x: .init(0),
                y: row2.ury,
                width: .init(100),
                height: rowHeight
            )

            #expect(row1.ury.ticks == 10580)
            #expect(row2.ury.ticks == 12760)
            #expect(row3.ury.ticks == 14940)

            let spanHeight: QGeometry.Height = .init(65.4)
            let span = QGeometry.Rectangle(
                x: .init(0),
                y: startY,
                width: .init(100),
                height: spanHeight
            )
            #expect(span.ury.ticks == 14940)
        }
    }
}
