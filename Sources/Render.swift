import CSDL2

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

