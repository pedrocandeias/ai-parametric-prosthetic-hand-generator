# Changelog

## Version 2.0 - 3D Rendering Integration

### Added
- **Full 3D Rendering**: Integrated OpenSCAD WASM for real-time 3D preview
- **model-viewer**: Using Google's model-viewer for interactive 3D display
- **Auto-render**: Parameters automatically trigger re-rendering (with 500ms debounce)
- **STL Export**: Full STL export functionality
- **GLB Preview**: Models are rendered to GLB format for smooth 3D viewing

### Changed
- **Editor Hidden**: Code editor is now hidden by default (still updates in background)
- **UI Updated**: Changed "Preview & Editor" to "3D Preview"
- **Immediate Preview**: Models render automatically when loaded or parameters change
- **Loading Indicator**: Added visual feedback during rendering

### Technical Details

#### Files Added
- `openscad.wasm` (9.2MB) - OpenSCAD compiled to WebAssembly
- `openscad-worker.js` (86KB) - Worker thread for non-blocking rendering
- `24c27bd4337db6fc47cb.wasm` - Additional WASM module
- `model-viewer.min.js` - 3D viewer component

#### Integration
The app now:
1. Loads OpenSCAD code with parameters
2. Sends code to Web Worker for rendering
3. Receives GLB binary output
4. Displays in model-viewer with camera controls
5. Supports STL export for 3D printing

#### Performance
- Rendering happens in Web Worker (non-blocking)
- Typical render time: 500ms - 3000ms depending on complexity
- Debounced parameter changes: 500ms delay
- 30-second timeout for complex models
- Memory-efficient: Old renders are cleaned up automatically

## Version 1.0 - Initial Release

### Features
- JSON/XML configuration support
- Dynamic parameter UI generation
- Multiple model support
- Parameter grouping
- Code generation with parameter replacement

---

## Usage

### Start the Application
```bash
cd openscad-parameter-editor
python3 -m http.server 8001
# Open http://localhost:8001/public/
```

### What to Expect
1. Select a model from dropdown
2. 3D preview renders automatically
3. Adjust parameters with sliders
4. Model updates in real-time
5. Export STL when ready

### Browser Compatibility
- Chrome 90+ ✅
- Firefox 88+ ✅
- Safari 14+ ✅
- Edge 90+ ✅

Requires:
- WebAssembly support
- Web Workers
- ES6 JavaScript
- model-viewer custom element

### Known Issues
- Large models (>5000 faces) may take 10+ seconds to render
- First render is slower (WASM initialization)
- STL export uses ASCII format (larger files)

### Tips
- Wait for "Rendered in Xms" status before making more changes
- Use Reset button if model looks wrong
- Check browser console for detailed error messages
- Reduce `$fn` values in OpenSCAD for faster preview

---

## Future Improvements
- [ ] Add render quality slider ($fn control)
- [ ] Binary STL export (smaller files)
- [ ] Render queue for rapid parameter changes
- [ ] Thumbnail generation
- [ ] Measurement tools
- [ ] Section view/cutaway
- [ ] Multiple material support
- [ ] Animation support
