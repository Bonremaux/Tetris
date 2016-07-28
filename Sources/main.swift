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

while game.state != .exiting {
    var event = SDL_Event()
    while SDL_PollEvent(&event) != 0 {
        game.handle(event: event, currentTime: elapsed())
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
