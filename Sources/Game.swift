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
    case pause
    case resume
    case rotate
    case shift(Direction)
    case fall(FallingMode)
    case exit
}

enum State {
    case starting
    case playing
    case paused
    case winning
    case gameover
    case exiting
}

typealias KeyCode = Int

enum KeyState {
    case pressed
    case released
}

struct KeyEvent {
    let keyCode: KeyCode
    let keyState: KeyState
}

extension State {
    static var keyBindings: [(State?, KeyCode?, KeyState, action: Action)] = {
        return [
            (nil,            SDLK_ESCAPE, .pressed,  Action.exit          ),
            (nil,            SDLK_q,      .pressed,  Action.exit          ),
            (State.starting, nil,         .pressed,  Action.play          ),
            (State.playing,  SDLK_DOWN,   .pressed,  Action.fall(.fast)   ),
            (State.playing,  SDLK_DOWN,   .released, Action.fall(.normal) ),
            (State.playing,  SDLK_UP,     .pressed,  Action.rotate        ),
            (State.playing,  SDLK_LEFT,   .pressed,  Action.shift(.left)  ),
            (State.playing,  SDLK_RIGHT,  .pressed,  Action.shift(.right) ),
            (State.playing,  SDLK_SPACE,  .pressed,  Action.fall(.drop)   ),
            (State.playing,  SDLK_RETURN, .pressed,  Action.pause         ),
            (State.paused,   nil,         .pressed,  Action.resume        ),
        ]
    }()

    func translate(keyEvent event: KeyEvent) -> Action? {
        let elem = State.keyBindings.first { (state, keyCode, keyState, _) in 
            return (state == self || state == nil) && (keyCode == event.keyCode || keyCode == nil)
            && keyState == event.keyState 
        }
        return elem?.action
    }

    func translate(event: SDL_Event) -> Action? {
        let eventType = SDL_EventType(event.type)

        if eventType == SDL_QUIT {
            return .exit
        }

        if [SDL_KEYDOWN, SDL_KEYUP].contains(eventType) {
            if event.key.repeat != 0 {
                return nil
            }
            let code = KeyCode(event.key.keysym.sym)
            let state = eventType == SDL_KEYDOWN ? KeyState.pressed : KeyState.released
            return translate(keyEvent: KeyEvent(keyCode: code, keyState: state))
        }

        return nil
    }
}

class Game {
    var state: State = .starting
    var field = Field(width: 10, height: 20)
    var current: Tetrimino? = nil
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
    var pauseLabel: TextCache

    init(canvas: Canvas) {
        scoreLabel = canvas.createTextCache(text: "Score: ", color: Color.yellow)
        scoreNumber = canvas.createNumberCache(color: Color.yellow)
        linesLabel = canvas.createTextCache(text: "Lines: ", color: Color.yellow)
        levelLabel = canvas.createTextCache(text: "Level: ", color: Color.yellow)
        gameoverLabel = canvas.createTextCache(text: "GAME OVER", color: Color.red)
        playLabel = canvas.createTextCache(text: "PLAY", color: Color.orange)
        winLabel = canvas.createTextCache(text: "YOU WIN!", color: Color.orange)
        pauseLabel = canvas.createTextCache(text: "PAUSED", color: Color.orange)
    }

    private func play(currentTime: Seconds) {
        state = .playing
        nextTickTime = currentTime
    }

    private func apply(action: Action, currentTime t: Seconds) {
        modified = true

        switch action {
            case .play: play(currentTime: t)
            case .pause: state = .paused
            case .resume: play(currentTime: t)
            case .exit: state = .exiting
            case .rotate: rotateTetrimino()
            case let .fall(mode): setFallingMode(mode, currentTime: t)
            case let .shift(dir): shiftTetrimino(dir)
        }
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
        modified = true

        if current == nil {
            let newTetrimino = Tetrimino(type: next ?? TetriminoType.random)
            if !field.touching(tetrimino: newTetrimino) {
                current = newTetrimino
                next = TetriminoType.random
                fallingMode = .normal
            }
            else {
                state = .gameover
                next = nil
            }
        }
        else {
            let moved = current!.moved(byOffset: Cell(0, 1))
            if field.touching(tetrimino: moved) {
                field.put(tetrimino: current!)
                current = nil
                let count = field.deleteFilledRows()
                if count > 0 {
                    let k = count > 1 ? 2 : 1
                    score += count * 10 * k
                }
                lines += count
                level = lines / 10 + 1
                if level >= 10 {
                    state = .winning
                    next = nil
                }
            }
            else {
                current = moved
            }
        }
    }

    private func rotateTetrimino() {
        guard let tet = current else {
            return
        }

        let rotated = tet.rotated()
        if !field.touching(tetrimino: rotated) {
            current = rotated
        }
    }

    private func setFallingMode(_ mode: FallingMode, currentTime: Seconds) {
        if current == nil {
            return
        }

        fallingMode = mode
        nextTickTime = currentTime + fallingMode.speed(forLevel: level)
    }

    private func shiftTetrimino(_ direction: Direction) {
        guard let tet = current else {
            return
        }

        let moved = tet.moved(byOffset: direction.offset)
        if !field.touching(tetrimino: moved) {
            current = moved
        }
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        field.draw(canvas, pos)
        current?.draw(canvas, pos)
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
        else if state == .paused {
            pauseLabel.draw(canvas, pos + Point(35, 150))
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
