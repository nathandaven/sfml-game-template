#include "States/MainMenuState.hpp"
#include "Game.hpp"
#include "Global.hpp"

MainMenuState::MainMenuState(GameDataRef data) :
	_data(data)
{
}

void MainMenuState::initState()
{
}

void MainMenuState::updateInputs()
{
	// Event Polling
	while (this->_data->window->pollEvent(this->event))
	{
		switch (this->event.type)
		{
			case sf::Event::Closed:
				this->_data->window->close();
				break;
			case sf::Event::KeyPressed:
				if (this->event.key.code == sf::Keyboard::Escape)
					this->_data->window->close();
				break;
			default:
				break;
		}
	}
}

// marks dt to not warn compiler
void MainMenuState::updateState(float dt __attribute__((unused)))
{
}

// marks dt to not warn compiler
void MainMenuState::drawState(float dt __attribute__((unused)))
{
	// just for fun, heres hello world text
	// SAMPLE RENDER CODE:

	// background color
	this->_data->window->clear(sf::Color::Black);

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
		(this->_data->window->getSize().x / 2) - (text.getLocalBounds().width / 2),
		(this->_data->window->getSize().y / 2) - (text.getLocalBounds().height / 2));

	// inside the main loop, between window.clear() and window.display()
	this->_data->window->draw(text);

	// END SAMPLE RENDER CODE

	// Displays rendered obejcts
	this->_data->window->display();
}