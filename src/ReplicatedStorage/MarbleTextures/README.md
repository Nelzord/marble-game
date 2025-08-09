Place your marble textures here as Roblox instances.

Runtime structure (under ReplicatedStorage):
- MarblesModule defines marble ids (e.g., Default, Red, Blue, Green)
- Add a folder per marble id under this folder:
  - ReplicatedStorage/MarbleTextures/<MarbleId>/
    - Put one or more `Texture` or `Decal` instances here

Notes:
- If you add a single `Texture` or `Decal`, the client will clone it across all 6 faces of the marble automatically.
- If you add multiple `Texture`/`Decal` instances with specific Face values, the client will clone them preserving faces.
- If no textures are provided for a marble id, the marble will use its fallback color from `MarblesModule`.

Recommended:
- Use `Texture` with appropriate `StudsPerTileU/V` for tiling on the sphere.
- Keep the folder name exactly matching the marble id from `MarblesModule`. 