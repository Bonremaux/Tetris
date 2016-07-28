import CSDL2

let blockSize = Point(20, 20)

extension Cell {
    func toCanvas() -> Point {
        return Point(Float(x), Float(y)) * blockSize
    }
}

extension SDL_Color {
    init(_ c: Color) {
        self = SDL_Color(r: c.r, g: c.g, b: c.b, a: c.a)
    }
}

class TextCache {
    var texture: OpaquePointer? = nil
    var width: Int32 = 0
    var height: Int32 = 0

    private init(canvas: Canvas, text: String, color c: Color) {
        let surface = TTF_RenderText_Blended(canvas.font, text, SDL_Color(c))
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

class NumberCache {
    class Glyph {
        let texture: OpaquePointer
        let width: Int32
        let height: Int32

        init(_ t: OpaquePointer, _ w: Int32, _ h: Int32) {
            texture = t
            width = w
            height = h
        }

        deinit {
            SDL_DestroyTexture(texture)
        }
    }

    var glyphs = [Character: Glyph]()

    private init(canvas: Canvas, color c: Color) {
        for char in "0123456789".characters {
            let surface = TTF_RenderText_Blended(canvas.font, String(char), SDL_Color(c))
            if surface != nil {
                let texture = SDL_CreateTextureFromSurface(canvas.renderer, surface)
                let width = surface!.pointee.w
                let height = surface!.pointee.h
                glyphs[char] = Glyph(texture!, width, height)
                SDL_FreeSurface(surface)
            }
        }
    }

    func draw(_ canvas: Canvas, _ pos: Point, numberString: String) {
        var p = pos
        for char in numberString.characters {
            if let glyph = glyphs[char] {
                var rect = SDL_Rect(x: Int32(p.x), y: Int32(p.y), w: glyph.width, h: glyph.height)
                SDL_RenderCopy(renderer, glyph.texture, nil, &rect)
                p += Point(Float(glyph.width), 0)
            }
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

    func createNumberCache(color: Color) -> NumberCache {
        return NumberCache(canvas: self, color: color)
    }

    func setColor(_ c: Color) {
        SDL_SetRenderDrawColor(renderer, c.r, c.g, c.b, c.a)
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
