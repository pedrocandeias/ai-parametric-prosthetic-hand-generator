# Quick Start Guide

## Get Running in 30 Seconds

### Step 1: Start the Server
```bash
cd openscad-parameter-editor
./start-server.sh
```

Or manually:
```bash
python3 -m http.server 8000
```

### Step 2: Open in Browser
Navigate to: **http://localhost:8000/public/**

### Step 3: Try It Out!
1. Select "Parametric Box" from the dropdown
2. Move the "width" slider
3. Watch the code update in real-time
4. Click "Reset to Defaults" to restore initial values
5. Click "Export STL" to download the OpenSCAD file

## What You'll See

### Main Interface Layout

```
┌──────────────────────────────────────────────────────────────┐
│ OpenSCAD Parameter Editor                                     │
│ Edit parameters of predefined OpenSCAD models                │
└──────────────────────────────────────────────────────────────┘
┌──────────────────┬────────────────────────────────────────────┐
│ Select Model:    │ Preview & Editor                           │
│ [Parametric Box ▼]  [Reset] [Render] [Export]                │
├──────────────────┤                                            │
│ Parametric Box   ├────────────────────────────────────────────┤
│ A simple box...  │                                            │
├──────────────────┤  /* [Dimensions] */                        │
│ === Dimensions ===  width = 75;                               │
│                  │  depth = 50;                               │
│ width: 75        │  height = 30;                              │
│ [━━━━━●━━━━━━]   │  wall_thickness = 2;                       │
│ 10          200  │                                            │
│                  │  /* [Style] */                             │
│ depth: 50        │  corner_radius = 5;                        │
│ [━━━━●━━━━━━━]   │                                            │
│ 10          200  │  /* [Features] */                          │
│                  │  lid = true;                               │
│ height: 30       │                                            │
│ [━━━●━━━━━━━━]   │  // Main module                            │
│ 5           100  │  module box() { ...                        │
│                  │                                            │
│ === Features ===  │                                            │
│ lid: true        │                                            │
│ [✓] Enable       │                                            │
└──────────────────┴────────────────────────────────────────────┘
│ Ready                                                          │
└────────────────────────────────────────────────────────────────┘
```

## Example Workflow

### Creating a Custom Box

1. **Select Model**: Choose "Parametric Box"

2. **Adjust Dimensions**:
   - Width: Move slider to 100mm
   - Depth: Move slider to 75mm
   - Height: Set to 40mm
   - Wall thickness: Adjust to 3mm

3. **Style Options**:
   - Corner radius: Set to 8mm for rounded corners

4. **Features**:
   - Check "Include lid" to add a lid

5. **Export**:
   - Click "Export STL" to download `box_[timestamp].scad`
   - Open in OpenSCAD desktop app to render

### Creating a Gear

1. **Select Model**: Choose "Parametric Gear"

2. **Gear Properties**:
   - Number of teeth: 30
   - Circular pitch: 8
   - Pressure angle: 20°

3. **Dimensions**:
   - Gear thickness: 6mm
   - Hub thickness: 12mm
   - Center bore: 6mm (for 6mm shaft)

4. **Export**: Download and render in OpenSCAD

## Testing Your Own Models

### 1. Create an OpenSCAD File

Create `models/mymodel.scad`:
```openscad
/* [Basic] */
size = 20;
quality = 50;

/* [Advanced] */
hollow = false;

$fn = quality;

if (hollow) {
    difference() {
        cube(size);
        translate([2,2,2]) cube(size-4);
    }
} else {
    cube(size);
}
```

### 2. Add to Configuration

Edit `models/models-config.json`:
```json
{
  "models": [
    {
      "id": "mymodel",
      "name": "My Custom Model",
      "description": "A test model",
      "file": "mymodel.scad",
      "parameters": [
        {
          "name": "size",
          "type": "number",
          "initial": 20,
          "min": 5,
          "max": 100,
          "step": 1,
          "caption": "Size of the cube",
          "group": "Basic"
        },
        {
          "name": "quality",
          "type": "number",
          "initial": 50,
          "min": 10,
          "max": 200,
          "step": 10,
          "caption": "Render quality ($fn)",
          "group": "Basic"
        },
        {
          "name": "hollow",
          "type": "boolean",
          "initial": false,
          "caption": "Make it hollow",
          "group": "Advanced"
        }
      ]
    }
  ]
}
```

### 3. Reload and Test

1. Refresh the browser page
2. Your model should appear in the dropdown
3. Test all parameters

## Tips & Tricks

### Parameter Names Must Match
- JSON config: `"name": "width"`
- OpenSCAD file: `width = 50;`
- These MUST be identical!

### Use Descriptive Groups
Group related parameters for better UX:
- "Dimensions" - sizes, lengths, thicknesses
- "Features" - boolean options
- "Style" - aesthetic choices
- "Advanced" - expert settings

### Set Reasonable Ranges
```json
{
  "name": "wall_thickness",
  "min": 1,    // Too thin won't print well
  "max": 10,   // Too thick is wasteful
  "step": 0.5  // Precision appropriate for 3D printing
}
```

### Use Step Values Wisely
- **0.1**: High precision (0.1, 0.2, 0.3...)
- **0.5**: Medium precision (0.5, 1.0, 1.5...)
- **1**: Whole numbers (1, 2, 3...)
- **5**: Coarse adjustments (5, 10, 15...)

## Troubleshooting

### "Configuration loaded successfully" but no models?
- Check JSON syntax with a validator
- Ensure `models` array is not empty
- Check browser console for errors

### Parameter not updating in code?
- Verify parameter name matches exactly
- Check for typos in OpenSCAD variable name
- Ensure parameter has a default value in .scad file

### Model selector says "Loading models..."?
- Check that server is running
- Verify `models-config.json` path is correct
- Check browser console for 404 errors

### Code updates but parameters don't?
- Clear browser cache
- Hard refresh (Ctrl+Shift+R)
- Check for JavaScript errors in console

## Next: Add 3D Preview

To add live 3D rendering:

1. **Copy from openscad-playground**:
   ```bash
   cp openscad-playground/dist/openscad.wasm public/
   cp openscad-playground/dist/openscad-worker.js public/
   ```

2. **Integrate renderer** (see OVERVIEW.md)

3. **Update viewer** to show 3D model

## Support

- Check README.md for full documentation
- See OVERVIEW.md for technical details
- Review openscad-playground examples

## Have Fun!

You now have a working parameter editor. Experiment with:
- Different parameter types
- Complex OpenSCAD models
- Custom configurations
- Your own 3D printable designs

Happy making! 🎉
