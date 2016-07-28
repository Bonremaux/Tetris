import CSDL2

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

enum Action {
    case play
    case rotate
    case shift(Direction)
    case fall(FallingMode)
    case exit
}

enum State {
    case starting
    case playing
    case winning
    case gameover
    case exiting

    func translate(event: SDL_Event) -> Action? {
        if event.type == SDL_QUIT.rawValue {
            return .exit
        }

        if event.type == SDL_KEYDOWN.rawValue || event.type == SDL_KEYUP.rawValue {
            if event.key.repeat != 0 {
                return nil
            }
            let key = Int(event.key.keysym.sym)
            let pressed = event.type == SDL_KEYDOWN.rawValue

            if pressed && [SDLK_q, SDLK_ESCAPE].contains({ $0 == key }) {
                return .exit
            }

            if self == .starting {
                if pressed && key == SDLK_RETURN {
                    return .play
                }
            }

            if self == .playing {
                if pressed {
                    switch key {
                        case SDLK_UP: return .rotate
                        case SDLK_DOWN: return .fall(.fast)
                        case SDLK_LEFT: return .shift(.left)
                        case SDLK_RIGHT: return .shift(.right)
                        case SDLK_SPACE: return .fall(.drop)
                        default: break
                    }
                }
                else {
                    switch key {
                        case SDLK_DOWN: return .fall(.normal)
                        default: break
                    }
                }
            }
        }

        return nil
    }
}

class Game {
    var state: State = .starting
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
    var gameoverLabel: TextCache
    var playLabel: TextCache
    var winLabel: TextCache

    init(canvas: Canvas) {
        scoreLabel = canvas.createTextCache(text: "Score: ", color: Color.yellow)
        scoreNumber = canvas.createNumberCache(color: Color.yellow)
        linesLabel = canvas.createTextCache(text: "Lines: ", color: Color.yellow)
        levelLabel = canvas.createTextCache(text: "Level: ", color: Color.yellow)
        gameoverLabel = canvas.createTextCache(text: "GAME OVER", color: Color.red)
        playLabel = canvas.createTextCache(text: "PLAY", color: Color.orange)
        winLabel = canvas.createTextCache(text: "YOU WIN!", color: Color.orange)
    }

    private func play(currentTime: Seconds) {
        state = .playing
        nextTickTime = currentTime
        newTetrimino()
    }

    private func apply(action: Action, currentTime t: Seconds) {
        switch action {
            case .play: play(currentTime: t)
            case .exit: state = .exiting
            case .rotate: rotateTetrimino()
            case let .fall(mode): setFallingMode(mode, currentTime: t)
            case let .shift(dir): shiftTetrimino(dir)
        }
        modified = true
    }

    func update(currentTime: Seconds) {
        if state == .playing {
            if (currentTime >= nextTickTime) {
                tick()
                nextTickTime = currentTime + fallingMode.speed(forLevel: level)
            }
        }
    }

    private func tick() {
        let moved = current.moved(byOffset: Cell(0, 1))
        if field.touching(tetrimino: moved) {
            field.put(tetrimino: current)
            let count = field.deleteFilledRows()
            if count > 0 {
                let k = count > 1 ? 2 : 1
                score += count * 10 * k
            }
            lines += count
            level = lines / 10 + 1
            if level < 10 {
                newTetrimino()
                if field.touching(tetrimino: current) {
                    state = .gameover
                }
            }
            else {
                state = .winning
                next = nil
            }
        }
        else {
            current = moved
        }
        modified = true
    }

    private func rotateTetrimino() {
        let rotated = current.rotated()
        if !field.touching(tetrimino: rotated) {
            current = rotated
        }
    }

    private func setFallingMode(_ mode: FallingMode, currentTime: Seconds) {
        fallingMode = mode
        nextTickTime = currentTime + fallingMode.speed(forLevel: level)
    }

    private func shiftTetrimino(_ direction: Direction) {
        let moved = current.moved(byOffset: direction.offset)
        if !field.touching(tetrimino: moved) {
            current = moved
        }
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
        if state == .gameover {
            gameoverLabel.draw(canvas, pos + Point(10, 150))
        }
        else if state == .starting {
            playLabel.draw(canvas, pos + Point(55, 150))
        }
        else if state == .winning {
            winLabel.draw(canvas, pos + Point(35, 150))
        }
    }

    private func drawBar(_ canvas: Canvas, _ pos: Point) {
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

    func handle(event: SDL_Event, currentTime t: Seconds) {
        if let action = state.translate(event: event) {
            apply(action: action, currentTime: t)
        }
    }
}
