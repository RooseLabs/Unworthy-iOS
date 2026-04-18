# Unworthy
A dark metroidvania game built in SpriteKit for iOS.

## Group
* Bruno Moreira (29561)
* Marco Alves de Sousa (27929)
* Vítor Guerra (27950)

## Game Concept

In the game, the protagonist must face the strange world of his nightmares, which reflect some of his greatest traumas. These nightmares are not just challenges to overcome, but also serve as a means to explore the emotional and psychological depth of the main character.

## Gameplay Loop

Unworthy's gameplay combines classic elements of the metroidvania genre, featuring world exploration and challenging combat. Players need to use strategy and precision to defeat their fears and advance through the game.

## Why it's fun

Unworthy is fun because it combines challenging combat with a strong emotional and atmospheric component. The player feels constant progression by overpowering enemies and exploring new areas, while the difficulty encourages skill improvement. Additionally, the mystery surrounding the story and the nightmares creates curiosity and motivation to keep playing.

## MVP scope

The minimum viable product will consist of a single playable level that demonstrates the core gameplay mechanics. The player will be able to move, jump, and perform basic attacks, while managing a health system represented by 5 lives (HP).

The level will include one enemy type with simple behavior, allowing the player to engage in combat and experience the fundamental challenge of the game. A basic respawn system will also be implemented, returning the player to a defined point upon death.

The focus is on delivering a functional and polished core loop (movement, combat, and survival) within a small, contained environment. More advanced features, such as multiple enemy types, complex level design, or boss encounters, are outside the scope of this initial version.

## Technical Plan (SpriteKit) 

The game will be developed using SpriteKit, with a clear separation between scenes (menu, game, and game over). Character movements will be implemented with basic physics (gravity, collisions). Enemies will have simple behaviors, such as patrolling and chasing. The combat system will be based on collision detection between attacks and enemies.
The game map will be assembled using the "Tiled" software and exported to a JSON file, which will be read and imported into SpriteKit (Swift) to build the scene at runtime.

## Biggest Risk + Mitigation

The biggest risk is the gameplay becoming frustrating, poorly balanced, or repetitive, especially in combat. To mitigate this, frequent playtesting will be conducted to adjust the difficulty, improve control responsiveness, and ensure that enemy patterns are fair and predictable. Another risk is a lack of clarity regarding objectives, which can be resolved with better visual design and player feedback.

## Future Ideas

In the future, we would like our game to have four distinct areas, with different enemies and bosses that, upon being defeated, would give the player a key to open a door and win the game. Throughout the progression, the player would also have to explore the world to acquire special abilities that would make them stronger, helping them defeat increasingly challenging enemies.
