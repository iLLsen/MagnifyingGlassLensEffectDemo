If you like this check out my other stuff [https://illsen.com/links/](https://illsen.com/links/)

## How to Set Up
This shader can be applied to any node that supports materials, specifically **MeshInstance2D** or **Sprite2D**, to create a magnifying glass or lens distortion effect.

### Steps to Apply the Shader:

1. **Create a new Shader Material**  
   - Select your **MeshInstance2D** or **Sprite2D** (or another node that supports materials).  
   - In the **Inspector**, scroll down to **Material** and click **[empty]** → **New ShaderMaterial**.

2. **Attach the Shader**  
   - Click on **ShaderMaterial** → **[empty]** → **New Shader**.  
   - Open the newly created Shader and paste the shader code inside.

3. **Customize the Effect**  
   - Adjust **radius** to change the size of the magnifying area.  
   - Increase **power** to control how strong the distortion is.  
   - If **transparent_texture** is **false**, the node texture will be multiplied with the current color (`COLOR *= tex_color;`), allowing for a blended effect (colored lens).

### Additional Notes:  
- The effect will be centered in the middle of the node.  
- The shader automatically accounts for the screen aspect ratio to keep the effect circular.
