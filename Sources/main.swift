import CSDL2
import Glibc

func elapsed() -> Seconds {
    return Double(SDL_GetTicks()) / 1000
}

func sdlFatal(_ str: String) {
    fatalError(str + ": \(String(validatingUTF8:SDL_GetError()) ?? "unknown error")");
}

srand(UInt32(time(nil)));

if SDL_Init(UInt32(SDL_INIT_VIDEO)) == -1 {
    sdlFatal("SDL_Init")
}

if TTF_Init() == -1 {
    sdlFatal("TTF_Init")
}

var window = SDL_CreateWindow("SDL Tutorial", 0, 0, 500, 500, SDL_WINDOW_SHOWN.rawValue)
if window == nil {
    sdlFatal("SDL_CreateWindow failed")
}

var renderer = SDL_CreateRenderer(window, -1, SDL_RENDERER_ACCELERATED.rawValue)
if renderer == nil {
    sdlFatal("SDL_CreateRenderer failed")
}

var canvas = Canvas(renderer: renderer!)

var game = Game(canvas: canvas)

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
