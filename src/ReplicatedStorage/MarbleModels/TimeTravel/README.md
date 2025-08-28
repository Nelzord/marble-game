# TimeTravel Marble Model

This folder contains the 3D model for the TimeTravel marble.

## Expected Structure
When in Studio, create a Model instance named "TimeTravel" containing:

### Required Components:
- `HumanoidRootPart` (Part) - A spherical part with the marble's appearance
- `Humanoid` - For character functionality

### Recommended Properties:
- HumanoidRootPart should be a Ball shape
- Size: Vector3.new(4, 4, 4) or similar
- Material: Neon or SmoothPlastic
- Color: RGB(150, 100, 255) - Purple
- Consider adding subtle transparency (0.1) for ethereal effect

### Optional Enhancements:
- Add clockwork or temporal visual elements
- Include subtle glow effects
- Consider adding particle effects for mystical appearance

## Notes
- If no model is provided, the server will generate a simple spherical character
- The server will automatically apply the marble's color and physics properties
- The model will be cloned for each player who equips this marble
