import CSDL2

class TextCache {
    var texture: OpaquePointer? = nil
    var width: Int32 = 0
    var height: Int32 = 0

    private init(canvas: Canvas, text: String, color c: Color) {
        if texture != nil {
            SDL_DestroyTexture(texture)
            texture = nil
        }
        let surface = TTF_RenderText_Blended(canvas.font, text, SDL_Color(r: c.0, g: c.1, b: c.2, a: c.3))
        if surface != nil {
            texture = SDL_CreateTextureFromSurface(canvas.renderer, surface)
            width = surface!.pointee.w
            height = surface!.pointee.h
            SDL_FreeSurface(surface)
        }
    }

    deinit {
        if texture != nil {
            SDL_DestroyTexture(texture)
        }
    }

    func draw(_ canvas: Canvas, _ pos: Point) {
        if (texture != nil) {
            var rect = SDL_Rect(x: Int32(pos.x), y: Int32(pos.y), w: width, h: height)
            SDL_RenderCopy(renderer, texture, nil, &rect)
        }
    }
}

class Canvas {
    private var renderer: OpaquePointer
    let font: OpaquePointer?

    init(renderer r: OpaquePointer) {
        renderer = r
        font = TTF_OpenFont("Data/GoodDog.otf", 50)
        if font == nil {
            fatalError("TTF_OpenFont: \(String(validatingUTF8:SDL_GetError())!)");
        }
    }

    deinit {
        TTF_CloseFont(font)
    }

    func createTextCache(text: String, color: Color) -> TextCache {
        return TextCache(canvas: self, text: text, color: color)
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
