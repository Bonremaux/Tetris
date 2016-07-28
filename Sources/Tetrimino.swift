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

    func blocks() -> [[Bool]] {
        return mask().map { $0.map { $0 != 0 } }
    }

    func cells() -> [Cell] {
        return mask().enumerated().flatMap { (y, row) in 
            return row.enumerated().filter{$0.1 != 0}.map { (x, _) in 
                return Cell(x, y)
            }
        }
    }

    var color: Color {
        switch self {
            case I: return Color.maroon
            case J: return Color.lightgrey
            case L: return Color.purple
            case O: return Color.slateblue
            case S: return Color.darkgreen
            case T: return Color.brown
            case Z: return Color.teal
        }
    }

    static var array: [TetriminoType] {
        return [.I, .J, .L, .O, .S, .T, .Z]
    }

    static var random: TetriminoType {
        return array[Int(rand()) % array.count]
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(self.color)
        for cell in cells() {
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}

func == (l: TetriminoType, r: TetriminoType) -> Bool {
    return l == r
}

class Tetrimino {
    let type: TetriminoType
    var blocks: [[Bool]]
    var pos: Cell

    init(type: TetriminoType) {
        self.type = type
        blocks = type.blocks()
        pos = Cell(4, 0)
        assert(blocks.count > 0 && blocks.count == blocks[0].count)
    }

    init(copyFrom: Tetrimino) {
        type = copyFrom.type
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
            return row.enumerated().filter{$0.1}.map { (x, _) in 
                return pos + Cell(x, y) 
            }
        }
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        for cell in cells() {
            canvas.setColor(type.color)
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}
