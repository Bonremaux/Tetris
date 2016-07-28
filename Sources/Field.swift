
class Field {
    let size: Cell
    private var rows = [[TetriminoType?]]()

    init(width: Int, height: Int) {
        size = Cell(width, height)
        for _ in 1...height {
            rows.append([TetriminoType?](repeating: nil, count: width))
        }
    }

    subscript(cell: Cell) -> TetriminoType? {
        get {
            return rows[cell.y][cell.x]
        }
        set {
            rows[cell.y][cell.x] = newValue
        }
    }

    func contains(cell at: Cell) -> Bool {
        return at.x >= 0 && at.y >= 0 && at.x < size.x && at.y < size.y
    }

    func deleteRow(_ i: Int) {
        rows.remove(at: i)
        rows.insert([TetriminoType?](repeating: nil, count: size.x), at: 0)
    }

    func findFilledRow() -> Int? {
        for (i, row) in rows.enumerated() {
            if !row.contains({ $0 == nil }) {
                return i
            }
        }
        return nil
    }

    func deleteFilledRows() -> Int {
        var count = 0
        while let i = findFilledRow() {
            deleteRow(i)
            count += 1
        }
        return count
    }

    func touching(tetrimino: Tetrimino) -> Bool {
        for cell in tetrimino.cells() {
            if !contains(cell: cell) || self[cell] != nil {
                return true
            }
        }
        return false
    }

    func put(tetrimino: Tetrimino) {
        for cell in tetrimino.cells() {
            self[cell] = tetrimino.type
        }
    }

    var bounds: Rect {
        return Rect(pos: Point(0, 0), size: size.toCanvas())
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(40, 25, 40))
        canvas.drawRect(rect: bounds.translated(to: pos))
        for x in 0..<size.x {
            for y in 0..<size.y {
                if let type = self[Cell(x, y)] {
                    canvas.setColor(type.color)
                    canvas.drawRect(rect: Rect(pos: pos + Cell(x, y).toCanvas(), size: blockSize))
                }
            }
        }
    }
}
