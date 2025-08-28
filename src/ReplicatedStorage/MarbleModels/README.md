Place your marble character models here as Model instances when in Studio.

Expected structure at runtime in ReplicatedStorage:
- ReplicatedStorage/MarbleModels/<MarbleId> (Model)

Each model should contain at minimum a `HumanoidRootPart` (a spherical `Part` is ideal) and a `Humanoid`.
If either is missing, the server will add them automatically.

MarbleIds used in this project (you can add more):
- Default (optional model; server can build a simple sphere if missing)
- Blue
- Speed
- Gold
- Spider
- TimeTravel 