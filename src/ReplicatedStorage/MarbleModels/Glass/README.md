# Glass Marble Model

This directory contains the model information for the Glass Marble.

## Model Details

The Glass Marble model should be created in Roblox Studio with the following specifications:

### Visual Properties
- **Shape**: Sphere (marble shape)
- **Material**: Glass
- **Color**: Light blue glass (RGB: 220, 240, 255)
- **Transparency**: 0.3 (semi-transparent)
- **Reflectance**: 0.5 (glass reflection)
- **Size**: Standard marble size (approximately 2x2x2 studs)

### Texture
- Apply the glass texture from `MarbleTextures/Glass/GlassTexture.txt`
- Use the texture ID: `rbxassetid://105354663033089`
- Set StudsPerTileU and StudsPerTileV to 1

### Special Effects
- **Point Light**: Cool blue light (RGB: 220, 240, 255) with range 8 and brightness 1.5
- **Particle Effects**: Glass particles and sparkles for visual appeal
- **Glow Effect**: Subtle blue glow when the ability is active

### Physics
- Standard marble physics
- No special collision properties
- The glass effects are handled by the ability system, not the model itself

## Usage

This model will be automatically cloned when a player selects the Glass marble. The model serves as the visual representation of the marble character, while the actual glass surface creation is handled by the Glass ability module.

## Related Files

- Ability: `src/ReplicatedStorage/Marbles/Abilities/Glass.luau`
- Texture: `src/ReplicatedStorage/MarbleTextures/Glass/`
- Module: `src/ReplicatedStorage/Marbles/MarblesModule.luau`
