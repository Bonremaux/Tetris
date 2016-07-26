import CSDL2
import Glibc

// ====================================================
//                       Model
// ====================================================

struct Cell {
    var x: Int
    var y: Int

    init(_ x: Int, _ y: Int) {
        self.x = x
        self.y = y
    }
}

func - (l: Cell, r: Cell) -> Cell {
    return Cell(l.x - r.x, l.y - r.y)
}

func + (l: Cell, r: Cell) -> Cell {
    return Cell(l.x + r.x, l.y + r.y)
}

func += (l: inout Cell, r: Cell) {
    l = l + r
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
            case .drop: return 0.0
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
}

// ====================================================
//                       Render
// ====================================================

struct Point {
    var x: Float
    var y: Float

    init(_ x: Float, _ y: Float) {
        self.x = x
        self.y = y
    }
}

func + (l: Point, r: Point) -> Point {
    return Point(l.x + r.x, l.y + r.y)
}

func * (l: Point, r: Point) -> Point {
    return Point(l.x * r.x, l.y * r.y)
}

struct Rect {
    var x: Float
    var y: Float
    var w: Float
    var h: Float

    init(pos p: Point, size s: Point) {
        x = p.x
        y = p.y
        w = s.x
        h = s.y
    }

    var position: Point {
        set {
            x = newValue.x
            y = newValue.y
        }
        get {
            return Point(x, y)
        }
    }

    var size: Point {
        set {
            w = newValue.x
            h = newValue.y
        }
        get {
            return Point(w, h)
        }
    }

    func translated(to point: Point) -> Rect {
        return Rect(pos: point + position, size: size)
    }
}

typealias Color = (UInt8, UInt8, UInt8, UInt8)

class Canvas {
    private var renderer: OpaquePointer

    init(renderer r: OpaquePointer) {
        renderer = r
    }

    func setColor(_ c: Color) {
        SDL_SetRenderDrawColor(renderer, c.0, c.1, c.2, c.3)
    }

    func clear() {
        SDL_RenderClear(renderer)
    }

    func drawRect(rect r: Rect) {
        var sdlRect = SDL_Rect(x: Int32(r.x), y: Int32(r.y), w: Int32(r.w), h: Int32(r.h))
        SDL_RenderFillRect(renderer, &sdlRect)
    }

    func present() {
        SDL_RenderPresent(renderer)
    }
}

let blockSize = Point(20, 20)

extension Cell {
    func toCanvas() -> Point {
        return Point(Float(x), Float(y)) * blockSize
    }
}

extension TetriminoType {
    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(0, 255, 0, 255))
        for cell in cells() {
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}

extension Field {
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

    var bounds: Rect {
        return Rect(pos: Point(0, 0), size: size.toCanvas())
    }
}

extension Tetrimino {
    func draw(_ canvas: Canvas, _ pos: Point) {
        canvas.setColor(Color(255, 0, 0, 255))
        for cell in cells() {
            canvas.drawRect(rect: Rect(pos: pos + cell.toCanvas(), size: blockSize))
        }
    }
}

extension Game {
    func draw(_ canvas: Canvas, _ pos: Point) {
        if next != nil {
            next!.draw(canvas, pos + field.bounds.size + Point(50, -300))
        }
        field.draw(canvas, pos)
        current.draw(canvas, pos)
    }
}

// ====================================================
//                       Main
// ====================================================

func elapsed() -> Seconds {
    return Double(SDL_GetTicks()) / 1000
}

SDL_Init(UInt32(SDL_INIT_VIDEO))

var window = SDL_CreateWindow("SDL Tutorial", 0, 0, 500, 500, SDL_WINDOW_SHOWN.rawValue)
assert(window != nil, "SDL_CreateWindow failed: \(String(validatingUTF8:SDL_GetError()))")

var renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
assert(renderer != nil, "SDL_GetRenderer failed: \(String(validatingUTF8:SDL_GetError()))")

var game = Game()
game.start(currentTime: elapsed())

var canvas = Canvas(renderer: renderer!)

var quit = false
while !quit {
    var event = SDL_Event()
    while SDL_PollEvent(&event) != 0 {
        switch event.type {
            case SDL_QUIT.rawValue:
                quit = true

            case SDL_KEYDOWN.rawValue:
                if event.key.repeat == 0 {
                    switch Int(event.key.keysym.sym) {
                    case SDLK_q:
                        quit = true

                    case SDLK_UP:
                        game.rotateTetrimino(clockwise: true)

                    case SDLK_DOWN:
                        game.setFallingMode(.fast, currentTime: elapsed())

                    case SDLK_LEFT:
                        game.shiftTetrimino(.left)

                    case SDLK_RIGHT:
                        game.shiftTetrimino(.right)

                    case SDLK_SPACE:
                        game.setFallingMode(.drop, currentTime: elapsed())

                    default:
                        break
                    }
                }

            case SDL_KEYUP.rawValue:
                if event.key.repeat == 0 {
                    switch Int(event.key.keysym.sym) {
                    case SDLK_DOWN:
                        game.setFallingMode(.normal, currentTime: elapsed())

                    default:
                        break
                    }
                }

            default:
                break
        }
    }

    game.update(currentTime: elapsed())

    if game.modified {
        canvas.setColor(Color(0, 0, 0, 255))
        canvas.clear()
        game.draw(canvas, Point(50, 50))
        canvas.present()
        game.modified = false
    }

    SDL_Delay(1)
}

SDL_Quit()
