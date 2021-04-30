
#include "Game.hpp"
#include "Global.hpp"

/*
	Personal SFML boilerplate for VSCode based on Andrew King's "sfml-vscode-boilerplate"
	Original can be found here: https://github.com/andrew-r-king/sfml-vscode-boilerplate
	Additional structure based on: https://youtu.be/kxb0GvBNOGU
 */
int main()
{

#if defined(_DEBUG)
	std::cout << "Hello World!" << std::endl;
#endif

	// initializing a new Game
	Game();

	return 0;
}
