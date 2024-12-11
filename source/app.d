import std.stdio;
import std.array;
import std.conv;
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
		this.font = TTF_OpenFont("assets/zed-mono-regular.ttf", 80);

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

	public void add_tab () {
		this.add_char(' ');
		this.add_char(' ');
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

	private void draw_line_number (int row, int line) {
		string n_string = to!string(line);
		auto c_string = (n_string ~ '\0').ptr; 
		SDL_Surface* surface = TTF_RenderText_Blended(font, c_string, SDL_Color(255, 255, 255, 255));
		SDL_Texture* texture = SDL_CreateTextureFromSurface(this.renderer, surface);
		SDL_FreeSurface(surface);
		SDL_RenderCopy(this.renderer, texture, null, new SDL_Rect(0, row * 40, 20, 40));
	}

	public void render_cursor (int row, int col) {
		SDL_Rect cursor = {col * 20, row * 40, 3, 40};
		SDL_SetRenderDrawColor(this.renderer, 255, 255, 255, 255);
		SDL_RenderFillRect(this.renderer, &cursor);
	}

	public void render () {
		this.draw_line_number(0, 0);

		int row = 0; // row is the real row of the pixel coordinate system
		int line = 0; // line is the line number that is displayed
		int col = 2;

		foreach (i, SDL_Texture* tex; texs) {
			if (this.text[i] == '\n') {
				line++;
				row++;
				col = 1;

				this.draw_line_number(row, line);
			}
			else if (col == this.cols) {
				row++;
				col = 2;

				SDL_RenderCopy(this.renderer, tex, null, new SDL_Rect(col * 20, row * 40, 20, 40));
			}
			else {
				SDL_RenderCopy(this.renderer, tex, null, new SDL_Rect(col * 20, row * 40, 20, 40));
			}
			col++;
		}

		this.render_cursor(row, col);
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
					else if (ev.key.keysym.sym == SDLK_TAB) boomit.add_tab();
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
