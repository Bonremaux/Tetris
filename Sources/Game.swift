
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
    var score = 0
    var lines = 0
    var modified = true

    var scoreLabel: TextCache
    var scoreNumber: NumberCache
    var linesLabel: TextCache

    init(canvas: Canvas) {
        scoreLabel = canvas.createTextCache(text: "Score: ", color: Color(255, 255, 0, 255))
        scoreNumber = canvas.createNumberCache(color: Color(255, 255, 0, 255))
        linesLabel = canvas.createTextCache(text: "Lines: ", color: Color(255, 255, 0, 255))
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
            let count = field.deleteFilledRows()
            score += count * 100
            lines += count
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
        drawBar(canvas, pos + Point(field.bounds.w + 30, 0))
    }

    func drawBar(_ canvas: Canvas, _ pos: Point) {
        if next != nil {
            next!.draw(canvas, pos + Point(0, 20))
        }

        scoreLabel.draw(canvas, pos + Point(0, 100))
        scoreNumber.draw(canvas, pos + Point(120, 100), numberString: String(score))

        linesLabel.draw(canvas, pos + Point(0, 150))
        scoreNumber.draw(canvas, pos + Point(120, 150), numberString: String(lines))
    }
}
