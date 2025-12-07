If you like this demo, check out my other work at [https://illsen.com/links/](https://illsen.com/links/).

## Godot 4 Demo Project for Magnifying Glass Shader

This demo showcases a **Magnifying Glass Shader** applied to a **MeshInstance2D** in the scene, which uses a **SphereMesh** and a texture. It demonstrates the lens distortion effect and how the shader works in real-time.

### How the Shader is Applied:

- The shader is applied to the **MeshInstance2D** node named **Glass** in the demo scene.
- The shader is pre-configured with the correct settings for **radius**, **power**, and **transparent texture**.

### Shader Configuration:

- **Radius**: Controls the size of the magnified area.
- **Power**: Adjusts the strength of the distortion effect.
- **Transparent Texture**: Set this to **false** to blend the node's texture with the shader’s color.


## Minigame Example

Scene: minigame.tscn
A small hidden object game included to demo the shader in a gameplay context.
Objective: Find missprinted letters in the newspaper.
Use the magnifying glass to reveal tiny hidden letters.
Find all letters to reveal the secret "Godot Engine" headline.
Optional: Find the hidden bugs scurrying around the page.

Controls: Mouse to move, click Hint for help.