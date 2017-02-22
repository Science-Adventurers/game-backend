# Science Museum Hack - February 2017

## Science Adventurers

- Make a team
- Choose a topic (like space!)
- Run around the Science Museum to find the object you're shown and answer a quiz question about it

This is the game server, please refer to <https://github.com/Science-Adventurers/game-frontend> if you're interested in the frontend.

Available at <https://smhack-game-api.herokuapp.com/>

## Tech

The application is a standalone [Elixir Phoenix](http://www.phoenixframework.org) application without any extra depencies (all data is bundled and loaded in memory).

## Setup

Assuming you have Elixir 1.4 installed, you can:

* Install dependencies with `mix deps.get`
* Start Phoenix endpoint with `mix phoenix.server`
* Run tests with `mix test`

## Interaction

All interaction is websockets-based, please refer to the frontend codebase to see how that works.

## Leaderboard

You can visit [`localhost:4000`](http://localhost:4000/api/leaderboard) to see the current leaderboard.
