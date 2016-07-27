import Glibc

let blockSize = Point(20, 20)

extension Cell {
    func toCanvas() -> Point {
        return Point(Float(x), Float(y)) * blockSize
    }
}

enum TetriminoType: Equatable {
    case I, J, L, O, S, T, Z
}

extension TetriminoType {
    func mask() -> [[Int]] {
        switch self {
            case I: return [[0,0,0,0],
                            [1,1,1,1],
                            [0,0,0,0],
                            [0,0,0,0]]

            case J: return [[1,1,1],
                            [0,0,1],
                            [0,0,0]]

            case L: return [[1,1,1],
                            [1,0,0],
                            [0,0,0]]

            case O: return [[1,1],
                            [1,1]]

            case S: return [[0,1,1],
                            [1,1,0],
                            [0,0,0]]

            case T: return [[1,1,1],
                            [0,1,0],
                            [0,0,0]]

            case Z: return [[1,1,0],
                            [0,1,1],
                            [0,0,0]]
        }
    }

    func blocks() -> [[TetriminoType?]] {
        return mask().map { $0.map { $0 == 0 ? nil : self } }
    }

    func cells() -> [Cell] {
        return mask().enumerated().flatMap { (y, row) in 
            return row.enumerated().filter{$0.1 != 0}.map { (x, _) in 
                return Cell(x, y)
            }
        }
    }

    static var array: [TetriminoType] {
        return [.I, .J, .L, .O, .S, .T, .Z]
    }

    static var random: TetriminoType {
        return array[Int(rand()) % array.count]
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(0, 255, 0, 255))
        for cell in cells() {
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}

func == (l: TetriminoType, r: TetriminoType) -> Bool {
    return l == r
}

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

    func deleteFilledRows() {
        while let i = findFilledRow() {
            deleteRow(i)
        }
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
            self[cell] = .L
        }
    }

    var bounds: Rect {
        return Rect(pos: Point(0, 0), size: size.toCanvas())
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(50, 25, 50, 255))
        canvas.drawRect(rect: bounds.translated(to: pos))
        for x in 0..<size.x {
            for y in 0..<size.y {
                if self[Cell(x, y)] != nil {
                    canvas.setColor(Color(0, 255, 0, 255))
                    canvas.drawRect(rect: Rect(pos: pos + Cell(x, y).toCanvas(), size: blockSize))
                }
            }
        }
    }
}

class Tetrimino {
    var blocks: [[TetriminoType?]]
    var pos: Cell

    init(type: TetriminoType) {
        blocks = type.blocks()
        pos = Cell(4, 0)
        assert(blocks.count > 0 && blocks.count == blocks[0].count)
    }

    init(copyFrom: Tetrimino) {
        blocks = copyFrom.blocks
        pos = copyFrom.pos
    }

    func rotated() -> Tetrimino {
        let tetrimino = Tetrimino(copyFrom: self)
        for y in 0..<blocks.count {
            for x in 0..<blocks.count {
                tetrimino.blocks[y][x] = blocks[blocks.count - x - 1][y]
            }
        }
        return tetrimino
    }

    func moved(byOffset offset: Cell) -> Tetrimino {
        let tetrimino = Tetrimino(copyFrom: self)
        tetrimino.pos += offset
        return tetrimino
    }

    func cells() -> [Cell] {
        return blocks.enumerated().flatMap { (y, row) in 
            return row.enumerated().filter{$0.1 != nil}.map { (x, _) in 
                return pos + Cell(x, y) 
            }
        }
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(255, 0, 0, 255))
        for cell in cells() {
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}

typealias Seconds = Double

enum Direction {
    case left, right

    var offset: Cell {
        let dy = self == .left ? -1 : 1
        return Cell(dy, 0)
    }
}

enum FallingMode {
    case normal
    case fast
    case drop

    var speed: Seconds {
        switch self {
            case .normal: return 0.5
            case .fast: return 0.05
            case .drop: return 0.005
        }
    }
}

class Game {
    var field = Field(width: 10, height: 20)
    var current = Tetrimino(type: .L)
    var next: TetriminoType? = nil
    var fallingMode: FallingMode = .normal
    var nextTickTime: Seconds = 0
    var modified = true

    var scoreLabel: TextCache

    init(canvas: Canvas) {
        scoreLabel = canvas.createTextCache(text: "Score: ", color: Color(255, 255, 0, 255))
    }

    func start(currentTime: Seconds) {
        nextTickTime = currentTime
        newTetrimino()
        modified = true
    }

    func update(currentTime: Seconds) {
        if (currentTime >= nextTickTime) {
            tick()
            nextTickTime = currentTime + fallingMode.speed
        }
    }

    private func tick() {
        let moved = current.moved(byOffset: Cell(0, 1))
        if field.touching(tetrimino: moved) {
            field.put(tetrimino: current)
            field.deleteFilledRows()
            newTetrimino()
        }
        else {
            current = moved
        }
        modified = true
    }

    func rotateTetrimino(clockwise f: Bool) {
        let rotated = current.rotated()
        if !field.touching(tetrimino: current) {
            current = rotated
            modified = true
        }
    }

    func setFallingMode(_ mode: FallingMode, currentTime: Seconds) {
        fallingMode = mode
        nextTickTime = currentTime + fallingMode.speed
    }

    func shiftTetrimino(_ direction: Direction) {
        let moved = current.moved(byOffset: direction.offset)
        if !field.touching(tetrimino: moved) {
            current = moved
        }
        modified = true
    }

    private func newTetrimino() {
        if next == nil {
            next = TetriminoType.random
        }
        current = Tetrimino(type: next!)
        next = TetriminoType.random
        fallingMode = .normal
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        field.draw(canvas, pos)
        current.draw(canvas, pos)
        drawBar(canvas, pos + Point(field.bounds.w, 0))
    }

    func drawBar(_ canvas: Canvas, _ pos: Point) {
        if next != nil {
            next!.draw(canvas, pos + Point(30, 20))
        }
        scoreLabel.draw(canvas, pos + Point(30, 100))
    }
}

