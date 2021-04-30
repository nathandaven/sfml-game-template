#pragma once

namespace Engine
{
class State
{
public:
	// SHOULD BE VIRTUAL
	State()
	{}
	virtual ~State()
	{}

	virtual void initState() = 0;
	virtual void updateInputs() = 0;
	virtual void updateState(float dt) = 0;
	virtual void drawState(float dt) = 0;
	virtual void pauseState()
	{}
	virtual void resumeState()
	{}

	sf::Event event;
};
}