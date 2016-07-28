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

func += (l: inout Point, r: Point) {
    l = l + r
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

struct Color {
    var r, g, b, a: UInt8

    init(_ r: UInt8, _ g: UInt8, _ b: UInt8, _ a: UInt8 = 255) {
        self.r = r
        self.g = g
        self.b = b
        self.a = a
    }

    init(hex: Int) {
        self.init(UInt8((hex >> 16) & 0xff), UInt8((hex >> 8) & 0xff), UInt8(hex & 0xff))
    }

    static let black = Color(hex: 0x000000)
    static let white = Color(hex: 0xFFFFFF)
    static let red = Color(hex: 0xFF0000)
    static let grey = Color(hex: 0x808080)
    static let blue = Color(hex: 0x0000FF)
    static let cyan = Color(hex: 0x00FFFF)
    static let orange = Color(hex: 0xFFA500)
    static let yellow = Color(hex: 0xFFFF00)
    static let lime = Color(hex: 0x00FF00)
    static let purple = Color(hex: 0x800080)
    static let maroon = Color(hex: 0x800000)
    static let pink = Color(hex: 0xFFF0CB)
    static let magenta = Color(hex: 0xFF00FF)
    static let green = Color(hex: 0x008000)
    static let indigo = Color(hex: 0x4B0082)
    static let crimson = Color(hex: 0xDC143C)
    static let amber = Color(hex: 0xFFBF00)
    static let lightgrey = Color(hex: 0xD3D3D3)
    static let navy = Color(hex: 0x000080)
    static let darkgreen = Color(hex: 0x006400)
    static let brown = Color(hex: 0xA52A2A)
    static let teal = Color(hex: 0x008080)
    static let slateblue = Color(hex: 0x6A5ACD)
}
