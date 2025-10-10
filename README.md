# Prosthetic Hand AI Parameter Generator

AI-powered prosthetic hand customization tool that generates optimal 3D printing parameters based on anthropometric data. Built on top of [openscad-playground](https://github.com/openscad/openscad-playground).

## Features

- **AI-Powered Parameter Suggestions**: Uses Claude (Anthropic) or GPT-4 (OpenAI) to analyze anthropometric data and suggest optimal parameters
- **3D Real-time Preview**: Live 3D rendering using OpenSCAD WebAssembly
- **Anthropometric Input**: Natural language input for user measurements (age, gender, height, weight, arm length, etc.)
- **Dynamic Parameter UI**: Automatically generates input controls (sliders, checkboxes, number inputs) based on parameter definitions
- **STL Export**: Export customized models ready for 3D printing
- **Parameter Groups**: Organize parameters into logical groups
- **Clean UI**: Modern, responsive interface for easy parameter editing

## Project Structure

```
openscad-parameter-editor/
├── index.html              # Main HTML interface
├── app.js                  # Application logic
├── config.json             # Your API keys (gitignored)
├── config.example.json     # Template for API keys
├── .htaccess              # Apache configuration
├── openscad.wasm          # OpenSCAD WebAssembly
├── openscad-worker.js     # Worker thread
├── browserfs.min.js       # Virtual filesystem
├── model-viewer.min.js    # 3D viewer
├── models/
│   ├── models-config.json  # Model definitions and parameters
│   └── fingerator.scad     # Prosthetic hand model
└── README.md
```

## Getting Started

### Quick Start

1. **Configure API Keys**:

   Copy the example configuration file:
   ```bash
   cp config.example.json config.json
   ```

   Edit `config.json` and add your API keys:
   ```json
   {
     "ai": {
       "provider": "anthropic",
       "anthropic_api_key": "YOUR_ANTHROPIC_API_KEY_HERE",
       "openai_api_key": "YOUR_OPENAI_API_KEY_HERE"
     }
   }
   ```

   Get your API keys:
   - **Anthropic (Claude)**: https://console.anthropic.com/
   - **OpenAI (GPT-4)**: https://platform.openai.com/api-keys

   **Note**: The `config.json` file is gitignored to protect your API keys.

2. **Serve the application** using any web server:

   ```bash
   # Using Python 3
   cd openscad-parameter-editor
   python3 -m http.server 8000

   # Using Node.js http-server
   npx http-server -p 8000

   # Using PHP
   php -S localhost:8000
   ```

3. **Open in browser**: Navigate to `http://localhost:8000/`

4. **Use the AI Assistant**:
   - Select the Fingerator model
   - Choose your AI provider (Anthropic or OpenAI)
   - Enter anthropometric data (e.g., "woman, 42 years old, 75kg, 172cm height, portugal, arm length 65cm")
   - Click "Get AI Suggestions"
   - The AI will analyze the data and automatically set optimal parameters
   - Review and adjust parameters as needed
   - Export the STL file for 3D printing

### Configuration Format

#### JSON Format (models-config.json)

```json
{
  "models": [
    {
      "id": "unique-id",
      "name": "Display Name",
      "description": "Model description",
      "file": "filename.scad",
      "parameters": [
        {
          "name": "parameter_name",
          "type": "number",
          "initial": 50,
          "min": 10,
          "max": 200,
          "step": 1,
          "caption": "Parameter description",
          "group": "Group Name"
        }
      ]
    }
  ]
}
```

#### Parameter Types

1. **Number Parameters**:
   ```json
   {
     "name": "width",
     "type": "number",
     "initial": 50,
     "min": 10,
     "max": 200,
     "step": 1,
     "caption": "Width of the object",
     "group": "Dimensions"
   }
   ```
   - With `min` and `max`: Generates a slider
   - Without `min`/`max`: Generates a number input

2. **Boolean Parameters**:
   ```json
   {
     "name": "include_lid",
     "type": "boolean",
     "initial": true,
     "caption": "Include a lid",
     "group": "Features"
   }
   ```

3. **String Parameters**:
   ```json
   {
     "name": "text",
     "type": "string",
     "initial": "Hello",
     "caption": "Text to display",
     "group": "Content"
   }
   ```

### OpenSCAD File Format

Your OpenSCAD files should include parameter declarations that match the configuration:

```openscad
/* [Dimensions] */
width = 50;
depth = 50;
height = 30;

/* [Features] */
include_lid = true;

// Your OpenSCAD code here
cube([width, depth, height]);
```

**Important**: Parameter names in the configuration must match the variable names in the OpenSCAD file.

## Adding Your Own Models

1. **Create your OpenSCAD file** in the `models/` directory
2. **Add parameter declarations** using the `/* [Group] */` comment syntax
3. **Update models-config.json** with your model definition and parameters
4. **Reload the page** and select your model from the dropdown

### Example: Adding a Cylinder Model

1. Create `models/cylinder.scad`:
```openscad
/* [Dimensions] */
radius = 10;
height = 20;

/* [Quality] */
$fn = 50;

cylinder(r=radius, h=height);
```

2. Add to `models-config.json`:
```json
{
  "id": "cylinder",
  "name": "Simple Cylinder",
  "description": "A basic parametric cylinder",
  "file": "cylinder.scad",
  "parameters": [
    {
      "name": "radius",
      "type": "number",
      "initial": 10,
      "min": 1,
      "max": 50,
      "step": 0.5,
      "caption": "Cylinder radius",
      "group": "Dimensions"
    },
    {
      "name": "height",
      "type": "number",
      "initial": 20,
      "min": 1,
      "max": 100,
      "step": 1,
      "caption": "Cylinder height",
      "group": "Dimensions"
    }
  ]
}
```

## Integration with OpenSCAD Playground

This project provides the UI framework for parameter editing. To add live 3D preview and STL export:

1. **Copy OpenSCAD WASM files** from openscad-playground:
   - `openscad.wasm`
   - `openscad-worker.js`
   - `libraries/` directory (fonts, etc.)

2. **Integrate the renderer** by adapting code from `openscad-playground/src/runner/`

3. **Update the viewer** to use the OpenSCAD renderer instead of showing static HTML

See the [openscad-playground repository](https://github.com/openscad/openscad-playground) for full WebAssembly integration details.

## XML Configuration Support

You can also use XML format for model configuration. Create `models-config.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<models>
  <model id="box" name="Parametric Box" file="box.scad">
    <description>A simple parametric box</description>
    <parameters>
      <parameter name="width" type="number" initial="50" min="10" max="200" step="1" group="Dimensions">
        <caption>Width of the box</caption>
      </parameter>
      <!-- More parameters... -->
    </parameters>
  </model>
</models>
```

To use XML configuration, modify `app.js` to parse XML instead of JSON.

## Browser Requirements

- Modern web browser with ES6+ support
- JavaScript enabled
- Local file access (for loading models)

## Limitations

This version includes:
- ✅ Parameter editing UI
- ✅ Live code updates
- ✅ JSON configuration
- ✅ Multiple model support

To add full functionality:
- ⏳ 3D preview rendering (requires OpenSCAD WASM integration)
- ⏳ STL export (requires OpenSCAD WASM integration)
- ⏳ Save/load custom parameter sets

## Contributing

Feel free to extend this project with:
- Additional parameter types (vectors, colors, enums)
- Advanced UI features (tabs, collapsible groups)
- OpenSCAD WASM integration for live preview
- Parameter preset saving/loading
- Batch export functionality

## Credits

- Based on [OpenSCAD Playground](https://github.com/openscad/openscad-playground)
- OpenSCAD: https://openscad.org/

## License

This project follows the licensing of openscad-playground. See their repository for details.
