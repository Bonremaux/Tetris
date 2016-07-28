import CSDL2
import Glibc

func elapsed() -> Seconds {
    return Double(SDL_GetTicks()) / 1000
}

srand(UInt32(time(nil)));

SDL_Init(UInt32(SDL_INIT_VIDEO))

if TTF_Init() == -1 {
    fatalError("TTF_Init: \(String(validatingUTF8:SDL_GetError())!)");
}

var window = SDL_CreateWindow("SDL Tutorial", 0, 0, 500, 500, SDL_WINDOW_SHOWN.rawValue)
assert(window != nil, "SDL_CreateWindow failed: \(String(validatingUTF8:SDL_GetError()))")

var renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
assert(renderer != nil, "SDL_GetRenderer failed: \(String(validatingUTF8:SDL_GetError()))")

var canvas = Canvas(renderer: renderer!)

var game = Game(canvas: canvas)
game.start(currentTime: elapsed())

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
        canvas.setColor(Color.black)
        canvas.clear()
        game.draw(canvas, Point(50, 50))
        canvas.present()
        game.modified = false
    }

    SDL_Delay(1)
}

TTF_Quit()
SDL_Quit()
