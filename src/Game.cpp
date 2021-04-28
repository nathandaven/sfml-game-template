#include "Game.hpp"

/*
	This Game object holds all of the primary game code and keeps it out of main.
	(based on: https://youtu.be/kxb0GvBNOGU)
	This also incorporates the cross-platform boilerplate created by Andrew King
	(found here: https://github.com/andrew-r-king/sfml-vscode-boilerplate)
 */

// private
void Game::initVariables()
{
	this->window = nullptr;
}
void Game::initWindow()
{
	// creating our window object
	this->window = new sf::RenderWindow();

	// in Windows at least, this must be called before creating the window
	float screenScalingFactor = platform.getScreenScalingFactor(this->window->getSystemHandle());

	// Use the screenScalingFactor to create video mode and set screen size - 720p by default
	this->videoMode.height = 720.0f * screenScalingFactor;
	this->videoMode.width = 1280.0f * screenScalingFactor;

	// creating our window view using the video mode and disabling resizablilty
	this->window->create(this->videoMode, "Test Game 1", sf::Style::Titlebar | sf::Style::Close);
	platform.setIcon(this->window->getSystemHandle());
}

// Constructors

Game::Game()
{
	this->initVariables();
	this->initWindow();
}

Game::~Game()
{
	delete this->window;
}

//Accessors
bool Game::isRunning() const
{
	return this->window->isOpen();
}

// Functions

void Game::updatePollEvents()
{
	// Event Polling
	while (this->window->pollEvent(this->event))
	{
		switch (this->event.type)
		{
			case sf::Event::Closed:
				this->window->close();
				break;
			case sf::Event::KeyPressed:
				if (this->event.key.code == sf::Keyboard::Escape)
					this->window->close();
				break;
			default:
				break;
		}
	}
}

void Game::update()
{
	this->updatePollEvents();
}

/*
@return null
renders all game objects on screen (clear -> render -> display)
 */
void Game::render()
{
	// just for fun, heres hello world text
	// SAMPLE RENDER CODE:

	// background color
	this->window->clear(sf::Color::Black);

	// write text
	sf::Text text;
	sf::Font font;

	// throws error if cant load font
	if (!font.loadFromFile("Content/joystix.ttf"))
	{
		// error...
		throw GameException("yeah");
	}

	// select the font
	text.setFont(font); // font is a sf::Font

	// set the string to display
	text.setString("Hello world!");

	// set the character size
	text.setCharacterSize(24); // in pixels, not points!

	// set the color
	text.setFillColor(sf::Color::White);

	// set the text style
	text.setStyle(sf::Text::Bold | sf::Text::Underlined);

	text.setPosition(
		(this->window->getSize().x / 2) - (text.getLocalBounds().width / 2),
		(this->window->getSize().y / 2) - (text.getLocalBounds().height / 2));

	// inside the main loop, between window.clear() and window.display()
	this->window->draw(text);

	// END SAMPLE RENDER CODE

	// Displays rendered obejcts
	this->window->display();
}