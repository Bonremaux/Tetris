import Glibc

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
