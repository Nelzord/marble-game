# Teleporting Marble Model

This folder contains the model for the Teleporting marble.

## Model Details

- **Marble Type**: Teleporting
- **Ability**: Teleports player 20 studs upward
- **Rarity**: 1/35 (rare)
- **Color**: Blue teleportation (RGB: 100, 200, 255)
- **Texture**: rbxassetid://73544653958153

## Setup Instructions

1. Create a Model instance in this folder
2. Add a Part with the following properties:
   - Shape: Ball
   - Size: (2, 2, 2) or appropriate marble size
   - Material: Neon
   - Color: Color3.fromRGB(100, 200, 255)
   - Transparency: 0.1 (slight transparency for ethereal effect)
3. Add a Texture or Decal with:
   - Texture: rbxassetid://73544653958153
   - Face: All faces or Front
   - StudsPerTileU: 1
   - StudsPerTileV: 1

## Visual Effects

The Teleporting marble should have:
- Blue energy glow effect
- Teleportation swirl patterns
- Magical particle effects when ability is used
- Neon material for the glow effect

## Ability Behavior

When activated, the Teleporting marble:
- Teleports the player 20 studs upward
- Creates blue energy particles that fly outward
- Provides a brief upward velocity boost
- Has an 8-second cooldown
- Shows visual teleportation effects
