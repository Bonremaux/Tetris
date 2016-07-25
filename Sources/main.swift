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

enum TetriminoType: Equatable {
    case I, J, L, O, S, T, Z

    func mask() -> [[Bool]] {
        switch self {
            case I: return [[true,  true,  true,  true]]

            case J: return [[true,  true,  true],
                            [false, false, true]]

            case L: return [[true,  true,  true],
                            [true,  false, false]]

            case O: return [[true,  true],
                            [true,  true]]

            case S: return [[false, true,  true],
                            [true,  true, false]]

            case T: return [[true,  true,  true],
                            [false, true, false]]

            case Z: return [[true,  true, false],
                            [false, true, true]]
        }
    }

    func blocks() -> [Cell] {
        return mask().enumerated().flatMap { (row, array) in 
            return array.enumerated().filter{$0.1}.map { (column, _) in 
                return Cell(row, column)
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

    func touching(blocks: [Cell]) -> Bool {
        for cell in blocks {
            if !contains(cell: cell) || self[cell] != nil {
                return true
            }
        }
        return false
    }

    func put(blocks: [Cell], type: TetriminoType) {
        for cell in blocks {
            self[cell] = type
        }
    }
}

extension Cell {
    func rotate90(clockwise f: Bool) -> Cell {
        let sin = f ? 1 : -1
        let cos = 0
        return Cell(x * cos - y * sin, x * sin + y * cos)
    }

    func rotate90(around c: Cell, clockwise f: Bool) -> Cell {
        var t = self - c
        t = t.rotate90(clockwise: f)
        return t + c
    }
}

class Tetrimino {
    let type: TetriminoType
    private var cells: [Cell]
    var origin: Cell
    var pos: Cell

    init(type t: TetriminoType) {
        type = t
        cells = t.blocks()
        origin = Cell(1, 1)
        pos = Cell(5, 2)
    }

    var blocks: [Cell] {
        return cells.map { pos + $0 }
    }

    func rotate(clockwise f: Bool) {
        cells = cells.map { $0.rotate90(around: origin, clockwise: f) }
    }
}

typealias Seconds = Double

enum Direction {
    case left, right
}

enum Speed {
    case normal
    case accelerated
    case drop

    var seconds: Seconds {
        switch self {
        case .normal: return 0.5
        case .accelerated: return 0.05
        case .drop: return 0.0
        }
    }
}

class Game {
    var field = Field(width: 10, height: 20)
    var current = Tetrimino(type: .L)
    var next: TetriminoType? = nil
    var speed: Speed = .normal
    var tickTime: Seconds = 0
    var modified = true

    func start(updateTime time: Seconds) {
        tickTime = time
        nextTetrimino()
        modified = true
    }

    func update(updateTime time: Seconds) {
        if (time >= tickTime) {
            tick()
            tickTime = time + speed.seconds
        }
    }

    private func tick() {
        let prevPos = current.pos
        current.pos.y += 1
        if field.touching(blocks: current.blocks) {
            current.pos = prevPos
            field.put(blocks: current.blocks, type: current.type)
            field.deleteFilledRows()
            nextTetrimino()
        }
        modified = true
    }

    func rotateTetrimino(clockwise f: Bool) {
        current.rotate(clockwise: f)
        if field.touching(blocks: current.blocks) {
            current.rotate(clockwise: !f)
        }
        modified = true
    }

    func dropTetrimino(updateTime time: Seconds) {
        speed = .drop
        tickTime = time
    }

    func shiftTetrimino(_ direction: Direction) {
        let prevPos = current.pos
        current.pos.x += direction == .left ? -1 : 1
        if field.touching(blocks: current.blocks) {
            current.pos = prevPos
        }
        modified = true
    }

    func accelerateTetrimino(_ accelerate: Bool, updateTime time: Seconds) {
        speed = accelerate ? .accelerated : .normal
        tickTime = time + speed.seconds
    }

    private func nextTetrimino() {
        if next == nil {
            next = TetriminoType.random
        }
        current = Tetrimino(type: next!)
        next = TetriminoType.random
        speed = .normal
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
        for cell in blocks() {
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
        for cell in blocks {
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
game.start(updateTime: elapsed())

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
                        game.accelerateTetrimino(true, updateTime: elapsed())

                    case SDLK_LEFT:
                        game.shiftTetrimino(.left)

                    case SDLK_RIGHT:
                        game.shiftTetrimino(.right)

                    case SDLK_SPACE:
                        game.dropTetrimino(updateTime: elapsed())

                    default:
                        break
                    }
                }

            case SDL_KEYUP.rawValue:
                if event.key.repeat == 0 {
                    switch Int(event.key.keysym.sym) {
                    case SDLK_DOWN:
                        game.accelerateTetrimino(false, updateTime: elapsed())

                    default:
                        break
                    }
                }

            default:
                break
        }
    }

    game.update(updateTime: elapsed())

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
