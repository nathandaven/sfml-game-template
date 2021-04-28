#include <catch2/catch.hpp>

// I made my own silly test! Enjoy
TEST_CASE("sf::RenderWindow", "[renderwindow]")
{
	sf::RenderWindow window(sf::VideoMode(200, 200), "SFML works!");

	REQUIRE(window.getSize().x == 200);
	REQUIRE(window.getSize().y == 200);

	sf::CircleShape shape(window.getSize().x / 2);
	shape.setFillColor(sf::Color::White);

	REQUIRE(shape.getRadius() == 100.0f);
	REQUIRE(shape.getFillColor() == sf::Color::White);
	REQUIRE(static_cast<int>(shape.getLocalBounds().width) == 198); // 🤔
	REQUIRE(static_cast<int>(shape.getLocalBounds().height) == 200);

	sf::Font font;
	font.loadFromFile("Content/joystix.ttf");

	sf::Text text;

	// select the font
	text.setFont(font); // font is a sf::Font

	// set the string to display
	text.setString("Nice!");

	// set the character size
	text.setCharacterSize(12); // in pixels, not points!

	// set the color
	text.setFillColor(sf::Color::White);

	// set the text style
	REQUIRE(text.getCharacterSize() == 12);
	REQUIRE(text.getFont() == &font);

	// Show the RenderWindow once
	window.clear();
	window.draw(text);
	window.display();

	REQUIRE(window.isOpen() == true);
}