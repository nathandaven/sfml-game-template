
#pragma once

#include "Global.hpp"
#include "States/State.hpp"

namespace Engine
{

typedef std::unique_ptr<State> StateRef;

class StateMachine
{

private:
	std::stack<Engine::StateRef> _states;
	Engine::StateRef _newState;

	bool _isRemoving;
	bool _isAdding;
	bool _isReplacing;

public:
	StateMachine()
	{}
	~StateMachine()
	{}

	void addState(StateRef newState, bool isReplacing);
	void removeState();
	void processStates();

	StateRef& getActiveState();
};
}