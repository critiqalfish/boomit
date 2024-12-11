import std.stdio;
import std.array;
import derelict.sdl2.sdl;
import derelict.sdl2.ttf;

class Boomit {
	public int win_width = 640;
	public int win_height = 480;
	public string text;
	public int cols;
	public SDL_Texture*[] texs;
	public SDL_Window* window;
	public SDL_Renderer* renderer;
	public TTF_Font* font;

	this() {
		this.cols = this.win_width / 20;
	}

	public void init_SDL () {
		DerelictSDL2.load();
		DerelictSDL2ttf.load();

		if (SDL_Init(SDL_INIT_VIDEO) != 0) {
			writeln("error video init");
		}

		if (TTF_Init() != 0) {
			writeln("error ttf init");
		}

		this.window = SDL_CreateWindow("boomit", 0, 0, this.win_width, this.win_height, SDL_WINDOW_SHOWN);
		this.renderer = SDL_CreateRenderer(this.window, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
		this.font = TTF_OpenFont("assets/SpaceMono-Regular.ttf", 80);

		SDL_SetHint(SDL_HINT_RENDER_SCALE_QUALITY, "1");

		SDL_StartTextInput();
	}

	public void add_char (char c) {
		this.text ~= c;

		char[2] cstring = [c, '\0'];
		SDL_Surface* surface = TTF_RenderText_Blended(font, cstring.ptr, SDL_Color(255, 255, 255, 255));
		SDL_Texture* texture = SDL_CreateTextureFromSurface(this.renderer, surface);
		SDL_FreeSurface(surface);

		this.texs ~= texture;
	}

	public void delete_char () {
		if (this.text.length < 1) return;
		this.text = this.text[0 .. $ -1];

		SDL_Texture* lastTex = this.texs[$ - 1];
		this.texs.popBack();
		if (lastTex !is null) {
			SDL_DestroyTexture(lastTex);
		}
	}

	public void render () {
		int r;
		int c;
		foreach (i, SDL_Texture* tex; texs) {
			if (this.text[i] == '\n') {
				r++;
				c = -1;
			}
			SDL_RenderCopy(this.renderer, tex, null, new SDL_Rect(c * 20, r * 20, 20, 40));
			c++;
		}
	}

	public void quit () {
		TTF_CloseFont(this.font);
		SDL_DestroyRenderer(this.renderer);
		SDL_DestroyWindow(this.window);
		SDL_Quit();
	}
}

void main () {
	Boomit boomit = new Boomit();
	boomit.init_SDL();

	bool run = true;
	while (run) {
		SDL_Event ev;
		while (SDL_PollEvent(&ev)) {
			switch (ev.type) {
				case SDL_QUIT:
					run = false;
					break;
				case SDL_TEXTINPUT:
					boomit.add_char(ev.text.text[0]);
					break;
				case SDL_KEYDOWN:
					if (ev.key.keysym.sym == SDLK_BACKSPACE) boomit.delete_char();
					else if (ev.key.keysym.sym == SDLK_RETURN) boomit.add_char('\n');
					else if (ev.key.keysym.sym == SDLK_TAB) {
						boomit.add_char(' ');
						boomit.add_char(' ');
					}
					break;
				default:
					break;
			}
		}

		SDL_SetRenderDrawColor(boomit.renderer, 24, 24, 24, 24);
		SDL_RenderClear(boomit.renderer);

		boomit.render();

		SDL_RenderPresent(boomit.renderer);

		SDL_Delay(1000 / 60);
	}

	boomit.quit();

	return;
}
