
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

    func speed(forLevel level: Int) -> Seconds {
        switch self {
            case .normal: return 0.8 - Double(level) * 0.07
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
    var score = 0
    var lines = 0
    var level = 1
    var modified = true

    var scoreLabel: TextCache
    var scoreNumber: NumberCache
    var linesLabel: TextCache
    var levelLabel: TextCache

    init(canvas: Canvas) {
        scoreLabel = canvas.createTextCache(text: "Score: ", color: Color.yellow)
        scoreNumber = canvas.createNumberCache(color: Color.yellow)
        linesLabel = canvas.createTextCache(text: "Lines: ", color: Color.yellow)
        levelLabel = canvas.createTextCache(text: "Level: ", color: Color.yellow)
    }

    func start(currentTime: Seconds) {
        nextTickTime = currentTime
        newTetrimino()
        modified = true
    }

    func update(currentTime: Seconds) {
        if (currentTime >= nextTickTime) {
            tick()
            nextTickTime = currentTime + fallingMode.speed(forLevel: level)
        }
    }

    private func tick() {
        let moved = current.moved(byOffset: Cell(0, 1))
        if field.touching(tetrimino: moved) {
            field.put(tetrimino: current)
            let count = field.deleteFilledRows()
            score += count * 100
            lines += count
            level = lines / 10 + 1
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
        nextTickTime = currentTime + fallingMode.speed(forLevel: level)
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
        drawBar(canvas, pos + Point(field.bounds.w + 30, 0))
    }

    func drawBar(_ canvas: Canvas, _ pos: Point) {
        let rect = Rect(pos: pos, size: Point(180, 100))
        canvas.setColor(Color(80, 50, 80))
        canvas.drawRect(rect: rect.expanded(thickness: 5))
        canvas.setColor(Color(20, 15, 20))
        canvas.drawRect(rect: rect)
        if next != nil {
            next!.draw(canvas, pos + Point(60, 30))
        }

        let numberOffset = Point(120, 0)
        var p = pos + Point(0, 130)

        scoreLabel.draw(canvas, p)
        scoreNumber.draw(canvas, p + numberOffset, numberString: String(score))

        p += Point(0, 60)
        linesLabel.draw(canvas, p)
        scoreNumber.draw(canvas, p + numberOffset, numberString: String(lines))

        p += Point(0, 60)
        levelLabel.draw(canvas, p)
        scoreNumber.draw(canvas, p + numberOffset, numberString: String(level))
    }
}
