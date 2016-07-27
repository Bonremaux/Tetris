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
