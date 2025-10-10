# OpenSCAD Parameter Editor - Project Overview

## What This Project Does

This is a web-based application that allows you to:
1. Define OpenSCAD models and their parameters in JSON or XML files
2. Load these models through a web interface
3. Edit parameters using automatically generated controls (sliders, inputs, checkboxes)
4. See the OpenSCAD code update in real-time as you change parameters
5. Export the modified OpenSCAD code for rendering

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Web Browser Interface                     │
│                                                               │
│  ┌──────────────┐  ┌───────────────────┐  ┌──────────────┐  │
│  │   Model      │  │   Parameter       │  │    Code      │  │
│  │   Selector   │  │   Controls        │  │    Editor    │  │
│  └──────────────┘  └───────────────────┘  └──────────────┘  │
└─────────────────────────────────────────────────────────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │   Application Logic   │
                    │      (app.js)        │
                    └───────────┬──────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
         ┌──────▼──────┐ ┌─────▼──────┐ ┌─────▼──────┐
         │   JSON/XML   │ │  OpenSCAD  │ │  OpenSCAD  │
         │   Config     │ │  File #1   │ │  File #2   │
         └──────────────┘ └────────────┘ └────────────┘
```

## Key Components

### 1. Configuration System (models-config.json/xml)
- **Purpose**: Define available models and their parameters
- **Format**: JSON or XML
- **Contains**:
  - Model metadata (name, description, file path)
  - Parameter definitions (type, ranges, defaults, grouping)

### 2. Web Interface (index.html)
- **Model Selector**: Dropdown to choose which model to edit
- **Parameter Panel**: Dynamically generated controls based on configuration
- **Code Editor**: Shows the OpenSCAD code with updated parameter values
- **Action Buttons**: Reset, Render, Export functionality

### 3. Application Logic (app.js)
- **Config Loader**: Reads and parses JSON configuration
- **UI Generator**: Creates parameter controls dynamically
- **Code Updater**: Replaces parameter values in OpenSCAD code
- **State Management**: Tracks current model and parameter values

### 4. OpenSCAD Files (*.scad)
- **Standard Format**: Uses OpenSCAD's customizer comment syntax
- **Parameter Declaration**: `/* [Group] */` followed by `variable = value;`
- **Compatible**: Works with existing OpenSCAD customizer files

## How It Works

### Step 1: Configuration Loading
```javascript
// App loads models-config.json at startup
{
  "models": [
    {
      "id": "box",
      "name": "Parametric Box",
      "file": "box.scad",
      "parameters": [...]
    }
  ]
}
```

### Step 2: Model Selection
User selects "Parametric Box" → App:
1. Loads `box.scad` file content
2. Reads parameter definitions from config
3. Generates UI controls for each parameter
4. Displays initial code in editor

### Step 3: Parameter Editing
User changes "width" from 50 to 100 → App:
1. Updates internal parameter state
2. Finds parameter in OpenSCAD code: `width = 50;`
3. Replaces with new value: `width = 100;`
4. Updates editor display

### Step 4: Export
User clicks "Export" → App:
1. Gets current code with updated parameters
2. Creates downloadable .scad file
3. Triggers browser download

## Parameter Types

### Number Parameters
```json
{
  "name": "width",
  "type": "number",
  "initial": 50,
  "min": 10,
  "max": 200,
  "step": 1
}
```
→ Generates: Slider (if min/max defined) or Number Input

### Boolean Parameters
```json
{
  "name": "include_lid",
  "type": "boolean",
  "initial": true
}
```
→ Generates: Checkbox

### String Parameters
```json
{
  "name": "label_text",
  "type": "string",
  "initial": "Hello"
}
```
→ Generates: Text Input

## Integration Points

### For Adding 3D Preview (from openscad-playground)

1. **Copy WASM Files**:
   - `openscad.wasm` (OpenSCAD compiled to WebAssembly)
   - `openscad-worker.js` (Worker thread for rendering)
   - Font libraries

2. **Integrate Renderer**:
   ```javascript
   // In app.js, replace renderPreview() with:
   async renderPreview() {
     const code = this.getUpdatedCode();
     const result = await openscadWorker.render(code);
     displayInViewer(result);
   }
   ```

3. **Update Viewer**:
   - Replace iframe with canvas or model-viewer element
   - Display rendered 3D model

### For Adding STL Export

```javascript
async exportSTL() {
  const code = this.getUpdatedCode();
  const stl = await openscadWorker.renderSTL(code);
  downloadFile(stl, 'model.stl');
}
```

## File Structure Explained

```
openscad-parameter-editor/
│
├── models/                          # Model definitions and files
│   ├── models-config.json          # Configuration (JSON format)
│   ├── models-config.xml           # Configuration (XML format)
│   ├── box.scad                    # Example model #1
│   └── gear.scad                   # Example model #2
│
├── public/                          # Web application files
│   ├── index.html                  # Main HTML interface
│   └── app.js                      # Application logic
│
├── README.md                        # User documentation
├── OVERVIEW.md                      # This file (technical overview)
└── start-server.sh                 # Quick start script
```

## Technology Stack

- **Frontend**: Vanilla JavaScript (ES6+)
- **Styling**: CSS3 with Flexbox
- **Server**: Any static file server (Python http.server, Node.js, etc.)
- **Dependencies**: None (self-contained)

## Extension Ideas

### 1. Advanced Parameter Types
- **Vector/Array**: `[10, 20, 30]` with multiple inputs
- **Color**: Color picker for RGB values
- **Dropdown/Enum**: Select from predefined options
- **File Upload**: Import external files as parameters

### 2. Preset Management
```javascript
// Save current parameter set
savePreset("my-custom-box", parameters);

// Load saved preset
loadPreset("my-custom-box");
```

### 3. Batch Export
- Generate multiple models with different parameters
- Create variations automatically
- Export as ZIP archive

### 4. Live Collaboration
- Share parameter configurations via URL
- Real-time parameter syncing between users
- Comment/annotation system

### 5. History/Undo
- Track parameter changes
- Undo/redo functionality
- Save editing history

## Performance Considerations

- **Lazy Loading**: Load OpenSCAD files only when selected
- **Debouncing**: Wait for user to finish editing before updating code
- **Worker Threads**: Use Web Workers for rendering (when integrated)
- **Caching**: Cache loaded configurations and files

## Security Notes

- Runs entirely in browser (no server-side execution)
- No external API calls
- Safe to use offline
- No data transmission (unless you add it)

## Browser Compatibility

- **Tested**: Chrome 90+, Firefox 88+, Safari 14+
- **Required Features**:
  - ES6 JavaScript
  - Fetch API
  - CSS Flexbox
  - File download API

## Development Workflow

### Adding a New Model

1. Create OpenSCAD file with parameters:
   ```openscad
   /* [Dimensions] */
   radius = 10;
   height = 20;

   cylinder(r=radius, h=height);
   ```

2. Add to configuration:
   ```json
   {
     "id": "cylinder",
     "name": "Cylinder",
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
       }
     ]
   }
   ```

3. Reload page and select from dropdown

### Debugging

- Open browser DevTools (F12)
- Check Console for errors
- Inspect Network tab for file loading issues
- Verify JSON syntax with validator

## Comparison with OpenSCAD Customizer

| Feature | OpenSCAD Desktop | This Editor |
|---------|------------------|-------------|
| Parameter UI | Built-in | Web-based |
| Preview | Native | Requires WASM integration |
| Configuration | Comments in .scad | JSON/XML file |
| Portability | Desktop app | Web browser |
| Extensibility | Limited | Full JavaScript control |
| Sharing | Send .scad file | Share URL (future) |

## Next Steps for Full Implementation

1. ✅ Basic UI and parameter editing
2. ⏳ Integrate OpenSCAD WASM from playground
3. ⏳ Add 3D preview rendering
4. ⏳ Implement STL export
5. ⏳ Add preset save/load
6. ⏳ Create gallery view of models
7. ⏳ Add URL parameter sharing

## Credits & References

- **OpenSCAD**: https://openscad.org/
- **OpenSCAD Playground**: https://github.com/openscad/openscad-playground
- **OpenSCAD Customizer**: https://en.wikibooks.org/wiki/OpenSCAD_User_Manual/Customizer

## License

MIT License (or follow openscad-playground licensing)
