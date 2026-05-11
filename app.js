// OpenSCAD Parameter Editor with 3D Renderer
class ParameterEditor {
    constructor() {
        this.config = null;
        this.aiConfig = null;
        this.currentModel = null;
        this.parameters = {};
        this.originalCode = '';
        this.dependencyFiles = [];
        this.worker = null;
        this.currentGlbUrl = null;
        this.codeModified = false;   // true when admin has hand-edited the SCAD textarea

        this.init();
    }

    async init() {
        // Load model configuration
        await this.loadConfiguration();

        // Setup event listeners
        this.setupEventListeners();

        // Populate model selector
        this.populateModelSelector();

        // Set up save/load config UI (wired after auth ready)
        this.setupConfigPanel();

        // Listen for auth events
        window.addEventListener('auth:login', () => this.onAuthChange());
        window.addEventListener('auth:logout', () => this.onAuthChange());
    }

    onAuthChange() {
        const user = Auth.getUser();
        const configsPanel = document.getElementById('saved-configs-panel');
        const editCodeBtn = document.getElementById('edit-code-btn');
        const showLogBtn = document.getElementById('show-log-btn');
        const isAdmin = user && user.role === 'admin';
        if (user) {
            this.loadConfigList();
            if (configsPanel && this.currentModel) configsPanel.style.display = 'block';
            if (editCodeBtn) editCodeBtn.style.display = isAdmin ? 'inline-block' : 'none';
            if (showLogBtn) showLogBtn.style.display = isAdmin ? 'inline-block' : 'none';
        } else {
            if (configsPanel) configsPanel.style.display = 'none';
            const select = document.getElementById('saved-config-select');
            if (select) select.innerHTML = '<option value="">-- Select saved config --</option>';
            if (editCodeBtn) editCodeBtn.style.display = 'none';
            if (showLogBtn) showLogBtn.style.display = 'none';
            // Close editor and log if open when logged out
            this.setCodeEditorOpen(false);
            this.setScadLogOpen(false);
        }
    }

    setCodeEditorOpen(open) {
        const container = document.getElementById('editor-container');
        const btn = document.getElementById('edit-code-btn');
        if (!container) return;
        if (open) {
            container.classList.add('open');
            if (btn) btn.textContent = 'Hide Code';
        } else {
            container.classList.remove('open');
            if (btn) btn.textContent = 'Edit Code';
        }
    }

    toggleCodeEditor() {
        const container = document.getElementById('editor-container');
        if (!container) return;
        this.setCodeEditorOpen(!container.classList.contains('open'));
    }

    setScadLogOpen(open) {
        const container = document.getElementById('scad-log-container');
        const btn = document.getElementById('show-log-btn');
        if (!container) return;
        if (open) {
            container.classList.add('open');
            if (btn) btn.textContent = 'Hide Log';
        } else {
            container.classList.remove('open');
            if (btn) btn.textContent = 'Show Log';
        }
    }

    toggleScadLog() {
        const container = document.getElementById('scad-log-container');
        if (!container) return;
        this.setScadLogOpen(!container.classList.contains('open'));
    }

    appendScadLog(text, cssClass) {
        const pre = document.getElementById('scad-log');
        if (!pre) return;
        // Clear placeholder on first real entry
        if (pre.querySelector('.log-empty')) pre.innerHTML = '';
        const span = document.createElement('span');
        if (cssClass) span.className = cssClass;
        span.textContent = text;
        pre.appendChild(span);
        pre.scrollTop = pre.scrollHeight;
    }

    clearScadLog() {
        const pre = document.getElementById('scad-log');
        if (pre) pre.innerHTML = '<span class="log-empty">No render yet.</span>';
    }

    async loadConfiguration() {
        try {
            const response = await fetch('models/models-config.json');
            this.config = await response.json();
            this.updateStatus('Configuration loaded successfully', 'success');
        } catch (error) {
            this.updateStatus('Error loading configuration: ' + error.message, 'error');
            console.error('Error loading configuration:', error);
        }
    }


    populateModelSelector() {
        const select = document.getElementById('model-select');
        select.innerHTML = '<option value="">-- Select a model --</option>';

        if (this.config && this.config.models) {
            this.config.models.forEach(model => {
                const option = document.createElement('option');
                option.value = model.id;
                option.textContent = model.name;
                select.appendChild(option);
            });
        }
    }

    setupEventListeners() {
        document.getElementById('model-select').addEventListener('change', (e) => {
            this.loadModel(e.target.value);
        });

        document.getElementById('reset-btn').addEventListener('click', () => {
            this.resetParameters();
        });

        document.getElementById('render-btn').addEventListener('click', () => {
            this.renderPreview();
        });

        document.getElementById('export-btn').addEventListener('click', () => {
            this.exportSTL();
        });

        document.getElementById('ai-suggest-btn').addEventListener('click', () => {
            this.getAISuggestions();
        });

        document.getElementById('edit-code-btn').addEventListener('click', () => {
            this.toggleCodeEditor();
        });

        document.getElementById('show-log-btn').addEventListener('click', () => {
            this.toggleScadLog();
        });

        document.getElementById('scad-log-clear-btn').addEventListener('click', () => {
            this.clearScadLog();
        });

        document.getElementById('editor-revert-btn').addEventListener('click', () => {
            this.revertEditorToParameters();
        });

        document.getElementById('editor').addEventListener('input', () => {
            const user = Auth.getUser();
            if (user && user.role === 'admin') {
                this.codeModified = true;
                const badge = document.getElementById('editor-modified-badge');
                if (badge) badge.style.display = 'inline';
            }
        });
    }

    async loadModel(modelId) {
        if (!modelId) {
            this.clearModel();
            return;
        }

        const model = this.config.models.find(m => m.id === modelId);
        if (!model) {
            this.updateStatus('Model not found', 'error');
            return;
        }

        this.currentModel = model;
        this.parameters = {};
        this.dependencyFiles = [];
        this.codeModified = false;
        const badge = document.getElementById('editor-modified-badge');
        if (badge) badge.style.display = 'none';

        // Initialize parameters with default values
        model.parameters.forEach(param => {
            this.parameters[param.name] = param.initial;
        });

        // Load OpenSCAD file
        try {
            const response = await fetch(`models/${model.file}`);
            this.originalCode = await response.text();

            // Load dependency files.
            // Each entry is either a string "rel/path.ext" or an object
            // { url: "server/path.ext", path: "wasm_flat_name.ext" } — the
            // object form lets files live in subdirs on the server while the
            // WASM virtual FS sees them at a flat root path (avoiding the
            // ErrnoError that occurs when writing to a non-existent subdir).
            const deps = model.dependencies || [];
            this.dependencyFiles = await Promise.all(deps.map(async (dep) => {
                const serverPath = typeof dep === 'string' ? dep : dep.url;
                const wasmPath  = typeof dep === 'string' ? dep : (dep.path || dep.url);
                const isBinary = /\.(stl|amf|3mf|off|obj)$/i.test(serverPath);
                if (isBinary) {
                    // Pass URL so the worker fetches it directly as ArrayBuffer.
                    return { path: `/${wasmPath}`, url: `models/${serverPath}` };
                }
                const r = await fetch(`models/${serverPath}`);
                return { path: `/${wasmPath}`, content: await r.text() };
            }));

            // Display model info
            this.displayModelInfo(model);

            // Generate parameter controls
            this.generateParameterControls(model.parameters);

            // Update editor
            this.updateEditor();

            this.updateStatus(`Loaded: ${model.name} — click "Render Preview" to render`, 'success');

            // Refresh saved configs list for this model
            if (typeof Auth !== 'undefined') this.loadConfigList();
        } catch (error) {
            this.updateStatus('Error loading model file: ' + error.message, 'error');
            console.error('Error loading model:', error);
        }
    }

    clearModel() {
        this.currentModel = null;
        this.parameters = {};
        this.originalCode = '';

        // Clear viewer
        const viewer = document.getElementById('viewer');
        if (viewer.src) {
            viewer.src = '';
        }

        document.getElementById('model-info').style.display = 'none';
        document.getElementById('ai-assistant').style.display = 'none';
        document.getElementById('parameters').innerHTML = `
            <p style="color: #666; text-align: center; padding: 2rem;">
                Select a model to edit its parameters
            </p>
        `;
        document.getElementById('editor').value = '';
        this.updateStatus('Ready', '');
    }

    displayModelInfo(model) {
        const infoDiv = document.getElementById('model-info');
        document.getElementById('model-name').textContent = model.name;
        document.getElementById('model-description').textContent = model.description;
        infoDiv.style.display = 'block';

        // Show AI assistant and saved configs panel (if authenticated)
        document.getElementById('ai-assistant').style.display = 'block';
        const configsPanel = document.getElementById('saved-configs-panel');
        if (configsPanel && typeof Auth !== 'undefined' && Auth.isAuthenticated()) {
            configsPanel.style.display = 'block';
        }
    }

    generateParameterControls(parameters) {
        const container = document.getElementById('parameters');

        // Group parameters
        const groups = {};
        parameters.forEach(param => {
            if (!groups[param.group]) {
                groups[param.group] = [];
            }
            groups[param.group].push(param);
        });

        // Generate HTML
        let html = '';
        for (const [groupName, params] of Object.entries(groups)) {
            html += `
                <div class="param-group">
                    <h3>${groupName}</h3>
            `;

            params.forEach(param => {
                html += this.generateParameterControl(param);
            });

            html += '</div>';
        }

        container.innerHTML = html;

        // Add event listeners
        parameters.forEach(param => {
            const input = document.getElementById(`param-${param.name}`);
            if (input) {
                input.addEventListener('change', () => {
                    this.updateParameter(param.name, input);
                });
                input.addEventListener('input', () => {
                    this.updateParameter(param.name, input);
                });
            }
        });
    }

    formatParamName(name) {
        // "palm_breadth_mm" → "Palm Breadth (in mm)"
        // "show_palm"       → "Show Palm"
        // "assembled"       → "Assembled"
        const hasMm = name.endsWith('_mm');
        const base = hasMm ? name.slice(0, -3) : name;
        const words = base.split('_').filter(Boolean)
            .map(w => w.charAt(0).toUpperCase() + w.slice(1))
            .join(' ');
        return hasMm ? `${words} (in mm)` : words;
    }

    generateParameterControl(param) {
        const value = this.parameters[param.name];
        const label = this.formatParamName(param.name);

        let controlHtml = '';

        if (param.type === 'boolean') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${label}</span>
                        <span class="param-value" id="value-${param.name}">${value}</span>
                    </div>
                    <div class="param-caption">${param.caption}</div>
                    <div class="checkbox-container">
                        <input type="checkbox" id="param-${param.name}" ${value ? 'checked' : ''}>
                        <label for="param-${param.name}">Enable</label>
                    </div>
                </div>
            `;
        } else if (param.type === 'number') {
            if (param.min !== undefined && param.max !== undefined) {
                controlHtml = `
                    <div class="param-item">
                        <div class="param-label">
                            <span class="param-name">${label}</span>
                            <span class="param-value" id="value-${param.name}">${value}</span>
                        </div>
                        <div class="param-caption">${param.caption}</div>
                        <input type="range"
                               id="param-${param.name}"
                               class="param-control"
                               min="${param.min}"
                               max="${param.max}"
                               step="${param.step || 1}"
                               value="${value}">
                        <div style="display: flex; justify-content: space-between; margin-top: 0.25rem; font-size: 0.75rem; color: #999;">
                            <span>${param.min}</span>
                            <span>${param.max}</span>
                        </div>
                    </div>
                `;
            } else {
                controlHtml = `
                    <div class="param-item">
                        <div class="param-label">
                            <span class="param-name">${label}</span>
                            <span class="param-value" id="value-${param.name}">${value}</span>
                        </div>
                        <div class="param-caption">${param.caption}</div>
                        <input type="number"
                               id="param-${param.name}"
                               class="param-control"
                               step="${param.step || 1}"
                               value="${value}">
                    </div>
                `;
            }
        } else if (param.type === 'enum') {
            const options = param.options.map(opt =>
                `<option value="${opt.value}" ${String(value) === String(opt.value) ? 'selected' : ''}>${opt.label}</option>`
            ).join('');
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${label}</span>
                    </div>
                    <div class="param-caption">${param.caption}</div>
                    <select id="param-${param.name}" class="param-control">${options}</select>
                </div>
            `;
        } else if (param.type === 'string') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${label}</span>
                        <span class="param-value" id="value-${param.name}">${value}</span>
                    </div>
                    <div class="param-caption">${param.caption}</div>
                    <input type="text"
                           id="param-${param.name}"
                           class="param-control"
                           value="${value}">
                </div>
            `;
        }

        return controlHtml;
    }

    updateParameter(paramName, input) {
        let value;

        if (input.type === 'checkbox') {
            value = input.checked;
        } else if (input.type === 'number' || input.type === 'range') {
            value = parseFloat(input.value);
        } else if (input.type === 'select-one') {
            // Enum: coerce string back to the correct JS type
            const raw = input.value;
            if (raw === 'true')  value = true;
            else if (raw === 'false') value = false;
            else if (!isNaN(raw) && raw !== '') value = parseFloat(raw);
            else value = raw;
        } else {
            value = input.value;
        }

        this.parameters[paramName] = value;

        // Update value display
        const valueDisplay = document.getElementById(`value-${paramName}`);
        if (valueDisplay) {
            valueDisplay.textContent = value;
        }

        // Update editor
        this.updateEditor();

        // Auto-render on parameter change with debouncing
        clearTimeout(this.renderTimeout);
        this.renderTimeout = setTimeout(() => {
            this.renderPreview();
        }, 1500); // Wait 1.5s after last change before re-rendering
    }

    updateEditor() {
        if (!this.currentModel) return;

        // When admin has hand-edited the code, don't overwrite their changes.
        if (this.codeModified) return;

        let code = this.originalCode;

        // Replace parameter values in the code
        this.currentModel.parameters.forEach(param => {
            const paramValue = this.parameters[param.name];

            // Match parameter declarations at the beginning of a line (with possible whitespace)
            // Use negative lookahead to ensure we're not matching comparison operators (==)
            const pattern = new RegExp(
                `^(\\s*${param.name}\\s*=(?!=)\\s*)[^;]+;`,
                'gm'
            );

            if (code.match(pattern)) {
                const scadValue = (param.type === 'string') ? `"${paramValue}"` : paramValue;
                code = code.replace(pattern, `$1${scadValue};`);
            }
        });

        // Append top-level render call for library-style files (no built-in call)
        if (this.currentModel.renderCall) {
            code += '\n' + this.currentModel.renderCall + '\n';
        }

        document.getElementById('editor').value = code;
    }

    revertEditorToParameters() {
        this.codeModified = false;
        const badge = document.getElementById('editor-modified-badge');
        if (badge) badge.style.display = 'none';
        this.updateEditor();
    }

    resetParameters() {
        if (!this.currentModel) return;

        this.currentModel.parameters.forEach(param => {
            this.parameters[param.name] = param.initial;

            const input = document.getElementById(`param-${param.name}`);
            if (input) {
                if (input.type === 'checkbox') {
                    input.checked = param.initial;
                } else {
                    input.value = param.initial;
                }
            }

            const valueDisplay = document.getElementById(`value-${param.name}`);
            if (valueDisplay) {
                valueDisplay.textContent = param.initial;
            }
        });

        this.updateEditor();
        this.renderPreview();
        this.updateStatus('Parameters reset to defaults', 'success');
    }

    async renderPreview() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }

        const code = document.getElementById('editor').value;
        this.showLoading(true);
        this.updateStatus('Rendering preview...', '');

        try {
            // Cancel any pending stale timeout and terminate previous worker
            clearTimeout(this._renderAbortTimeout);
            if (this.worker) {
                this.worker.terminate();
                this.worker = null;
            }

            this.worker = new Worker('openscad-worker.js');

            const isAdmin = Auth.getUser()?.role === 'admin';
            if (isAdmin) this.clearScadLog();

            const resultPromise = new Promise((resolve, reject) => {
                this.worker.onmessage = (e) => {
                    if (e.data.result) {
                        resolve(e.data.result);
                    } else if (e.data.stderr) {
                        console.log('OpenSCAD stderr:', e.data.stderr);
                        if (isAdmin) {
                            const cls = /WARNING/i.test(e.data.stderr) ? 'log-warning' : 'log-stderr';
                            this.appendScadLog(e.data.stderr + '\n', cls);
                        }
                    } else if (e.data.stdout) {
                        console.log('OpenSCAD stdout:', e.data.stdout);
                        if (isAdmin) this.appendScadLog(e.data.stdout + '\n', 'log-stdout');
                    }
                };

                this.worker.onerror = (error) => {
                    reject(error);
                };

                this._renderAbortTimeout = setTimeout(() => {
                    reject(new Error('Rendering timeout (>120s)'));
                }, 120000);
            });

            // Per-model backend override: model config may specify renderBackend
            // ('manifold' default, '' to omit the flag and let WASM pick, 'cgal' for tolerance)
            const backendFlag = (this.currentModel && this.currentModel.renderBackend !== undefined)
                ? this.currentModel.renderBackend
                : 'manifold';
            const backendArgs = backendFlag ? ['--backend', backendFlag] : [];

            const useArchiveLibraries = !!(this.currentModel && this.currentModel.mountArchives);

            this.worker.postMessage({
                inputs: [
                    {path: '/input.scad', content: code},
                    ...(this.dependencyFiles || []),
                ],
                args: [
                    '/input.scad',
                    '-o', '/output.off',
                    '--export-format', 'off',
                    ...backendArgs,
                ],
                outputPaths: ['/output.off'],
                mountArchives: useArchiveLibraries
            });

            // Wait for result
            const result = await resultPromise;
            clearTimeout(this._renderAbortTimeout);

            // Clean up old URL
            if (this.currentGlbUrl) {
                URL.revokeObjectURL(this.currentGlbUrl);
            }

            // Check if we have output
            if (result.outputs && result.outputs.length > 0) {
                const offData = result.outputs[0][1];
                console.log('Output data type:', typeof offData, 'Length:', offData?.length);

                // Convert Uint8Array to text
                const offText = new TextDecoder().decode(offData);
                console.log('OFF file preview:', offText.substring(0, 100));

                // Parse OFF and convert to GLB
                try {
                    const glbBlob = await this.convertOFFtoGLB(offText);
                    console.log('Created GLB blob, size:', glbBlob.size);

                    // Clean up old URL
                    if (this.currentGlbUrl) {
                        URL.revokeObjectURL(this.currentGlbUrl);
                    }

                    this.currentGlbUrl = URL.createObjectURL(glbBlob);

                    // Update model viewer
                    const viewer = document.getElementById('viewer');
                    viewer.src = this.currentGlbUrl;

                    this.updateStatus(`Rendered in ${result.elapsedMillis}ms`, 'success');
                } catch (e) {
                    console.error('GLB conversion error:', e);
                    this.updateStatus('Failed to convert to GLB: ' + e.message, 'error');
                }
            } else {
                const errMsg = result.error || (result.mergedOutputs || [])
                    .filter(m => m.stderr || m.error)
                    .map(m => m.stderr || m.error)
                    .join(' ') || 'No output generated';
                this.updateStatus(errMsg.substring(0, 120), 'error');
                console.error('OpenSCAD error:', result);
            }

        } catch (error) {
            this.updateStatus('Rendering error: ' + error.message, 'error');
            console.error('Rendering error:', error);
        } finally {
            this.showLoading(false);
        }
    }

    // Parse OFF file and convert to GLB
    async convertOFFtoGLB(offText) {
        // Parse OFF format
        const lines = offText.split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));

        let currentLine = 0;
        let counts;

        // Handle OFF header
        if (lines[0].match(/^OFF(\s|$)/)) {
            counts = lines[0].substring(3).trim();
            currentLine = 1;
        } else if (lines[0] === 'OFF') {
            counts = lines[1];
            currentLine = 2;
        } else {
            throw new Error('Invalid OFF file: missing OFF header');
        }

        const [numVertices, numFaces] = counts.split(/\s+/).map(Number);
        console.log(`OFF file has ${numVertices} vertices and ${numFaces} faces`);

        // Parse vertices
        const vertices = [];
        for (let i = 0; i < numVertices; i++) {
            const parts = lines[currentLine + i].split(/\s+/).map(Number);
            vertices.push(parts[0], parts[1], parts[2]);
        }
        currentLine += numVertices;

        // Parse faces and triangulate
        const indices = [];
        for (let i = 0; i < numFaces; i++) {
            const parts = lines[currentLine + i].split(/\s+/).map(Number);
            const n = parts[0]; // number of vertices in this face
            const faceVerts = parts.slice(1, n + 1);

            // Triangulate polygon (simple fan triangulation)
            for (let j = 1; j < faceVerts.length - 1; j++) {
                indices.push(faceVerts[0], faceVerts[j], faceVerts[j + 1]);
            }
        }

        console.log(`Converted to ${vertices.length / 3} vertices and ${indices.length / 3} triangles`);

        // Create a simple GLB file
        return this.createSimpleGLB(new Float32Array(vertices), new Uint32Array(indices));
    }

    // Create a minimal GLB binary file
    createSimpleGLB(vertices, indices) {
        // GLB structure: Header + JSON chunk + Binary chunk

        const scene = {
            asset: { version: "2.0", generator: "Prosthetic Hand AI Parameter Generator" },
            scene: 0,
            scenes: [{ nodes: [0] }],
            nodes: [{ mesh: 0 }],
            meshes: [{
                primitives: [{
                    attributes: { POSITION: 0 },
                    indices: 1,
                    material: 0
                }]
            }],
            materials: [{
                pbrMetallicRoughness: {
                    baseColorFactor: [0.2, 0.1, 0.8, 1.0],
                    metallicFactor: 0.0,
                    roughnessFactor: 0.8
                },
                doubleSided: true
            }],
            buffers: [{ byteLength: 0 }],
            bufferViews: [
                { buffer: 0, byteOffset: 0, byteLength: vertices.byteLength, target: 34962 },
                { buffer: 0, byteOffset: vertices.byteLength, byteLength: indices.byteLength, target: 34963 }
            ],
            accessors: [
                {
                    bufferView: 0,
                    byteOffset: 0,
                    componentType: 5126,
                    count: vertices.length / 3,
                    type: "VEC3",
                    max: [Math.max(...vertices.filter((_, i) => i % 3 === 0)),
                          Math.max(...vertices.filter((_, i) => i % 3 === 1)),
                          Math.max(...vertices.filter((_, i) => i % 3 === 2))],
                    min: [Math.min(...vertices.filter((_, i) => i % 3 === 0)),
                          Math.min(...vertices.filter((_, i) => i % 3 === 1)),
                          Math.min(...vertices.filter((_, i) => i % 3 === 2))]
                },
                {
                    bufferView: 1,
                    byteOffset: 0,
                    componentType: 5125,
                    count: indices.length,
                    type: "SCALAR"
                }
            ]
        };

        // Update buffer byte length
        scene.buffers[0].byteLength = vertices.byteLength + indices.byteLength;

        const jsonString = JSON.stringify(scene);
        const jsonBuffer = new TextEncoder().encode(jsonString);

        // Align to 4-byte boundary
        const jsonPadding = (4 - (jsonBuffer.length % 4)) % 4;
        const jsonChunkLength = jsonBuffer.length + jsonPadding;

        const binaryBuffer = new Uint8Array(vertices.byteLength + indices.byteLength);
        binaryBuffer.set(new Uint8Array(vertices.buffer), 0);
        binaryBuffer.set(new Uint8Array(indices.buffer), vertices.byteLength);

        const binaryPadding = (4 - (binaryBuffer.length % 4)) % 4;
        const binaryChunkLength = binaryBuffer.length + binaryPadding;

        // Create GLB file
        const totalLength = 12 + 8 + jsonChunkLength + 8 + binaryChunkLength;
        const glb = new ArrayBuffer(totalLength);
        const view = new DataView(glb);
        let offset = 0;

        // GLB header
        view.setUint32(offset, 0x46546C67, true); offset += 4; // magic: "glTF"
        view.setUint32(offset, 2, true); offset += 4; // version
        view.setUint32(offset, totalLength, true); offset += 4; // length

        // JSON chunk
        view.setUint32(offset, jsonChunkLength, true); offset += 4;
        view.setUint32(offset, 0x4E4F534A, true); offset += 4; // "JSON"
        new Uint8Array(glb, offset, jsonBuffer.length).set(jsonBuffer); offset += jsonBuffer.length;
        for (let i = 0; i < jsonPadding; i++) view.setUint8(offset++, 0x20); // space padding

        // Binary chunk
        view.setUint32(offset, binaryChunkLength, true); offset += 4;
        view.setUint32(offset, 0x004E4942, true); offset += 4; // "BIN\0"
        new Uint8Array(glb, offset, binaryBuffer.length).set(binaryBuffer); offset += binaryBuffer.length;
        for (let i = 0; i < binaryPadding; i++) view.setUint8(offset++, 0);

        return new Blob([glb], { type: 'model/gltf-binary' });
    }

    base64ToArrayBuffer(data) {
        // Check if data is already an ArrayBuffer or Uint8Array
        if (data instanceof ArrayBuffer) {
            return data;
        }
        if (data instanceof Uint8Array) {
            return data.buffer;
        }

        // If it's a string, try to decode as base64
        if (typeof data === 'string') {
            try {
                const binaryString = atob(data);
                const bytes = new Uint8Array(binaryString.length);
                for (let i = 0; i < binaryString.length; i++) {
                    bytes[i] = binaryString.charCodeAt(i);
                }
                return bytes.buffer;
            } catch (e) {
                console.error('Base64 decode error:', e);
                // If base64 decode fails, try treating as raw binary string
                const bytes = new Uint8Array(data.length);
                for (let i = 0; i < data.length; i++) {
                    bytes[i] = data.charCodeAt(i) & 0xff;
                }
                return bytes.buffer;
            }
        }

        // Fallback: return as-is
        return data;
    }

    async exportSTL() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }

        const code = document.getElementById('editor').value;
        this.showLoading(true);
        this.updateStatus('Exporting STL...', '');

        try {
            // Create worker for STL export
            const worker = new Worker('openscad-worker.js');

            const resultPromise = new Promise((resolve, reject) => {
                worker.onmessage = (e) => {
                    if (e.data.result) {
                        resolve(e.data.result);
                    }
                };
                worker.onerror = reject;
                setTimeout(() => reject(new Error('Export timeout')), 60000);
            });

            // Send export request
            const useArchiveLibraries = !!(this.currentModel && this.currentModel.mountArchives);

            worker.postMessage({
                inputs: [
                    {path: '/input.scad', content: code},
                    ...(this.dependencyFiles || []),
                ],
                args: [
                    '/input.scad',
                    '-o', '/output.stl',
                    '--export-format', 'asciistl'
                ],
                outputPaths: ['/output.stl'],
                mountArchives: useArchiveLibraries
            });

            const result = await resultPromise;
            worker.terminate();

            if (result.outputs && result.outputs.length > 0) {
                const stlData = result.outputs[0][1];
                const stlText = atob(stlData);
                const blob = new Blob([stlText], { type: 'model/stl' });
                const url = URL.createObjectURL(blob);
                const a = document.createElement('a');
                a.href = url;
                a.download = `${this.currentModel.id}_${Date.now()}.stl`;
                document.body.appendChild(a);
                a.click();
                document.body.removeChild(a);
                URL.revokeObjectURL(url);

                this.updateStatus('STL exported successfully', 'success');
            } else {
                this.updateStatus('STL export failed', 'error');
            }

        } catch (error) {
            this.updateStatus('Export error: ' + error.message, 'error');
            console.error('Export error:', error);
        } finally {
            this.showLoading(false);
        }
    }

    showLoading(show) {
        const loading = document.getElementById('loading');
        if (show) {
            loading.classList.add('active');
        } else {
            loading.classList.remove('active');
        }
    }

    updateStatus(message, type = '') {
        const statusDiv = document.getElementById('status');
        statusDiv.textContent = message;
        statusDiv.className = 'status';

        if (type) {
            statusDiv.classList.add(type);
        }

        // Clear success/error messages after 3 seconds
        if (type === 'success' || type === 'error') {
            setTimeout(() => {
                if (statusDiv.textContent === message) {
                    statusDiv.textContent = 'Ready';
                    statusDiv.className = 'status';
                }
            }, 3000);
        }
    }

    async getAISuggestions() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }

        if (!Auth.isAuthenticated()) {
            this.updateStatus('Please log in to use AI suggestions', 'error');
            return;
        }

        const anthropometricInput = document.getElementById('anthropometric-input').value.trim();
        const apiProvider = document.getElementById('ai-provider').value;

        if (!anthropometricInput) {
            this.updateStatus('Please enter anthropometric data', 'error');
            return;
        }

        this.showLoading(true);
        this.updateStatus('Getting AI suggestions...', '');

        try {
            const promptText = `Based on the following anthropometric data for a prosthetic finger/hand:

${anthropometricInput}

Please analyze this information and suggest appropriate values for the following parameters for a 3D-printed prosthetic finger (Fingerator model):

Current parameters:
${JSON.stringify(this.currentModel.parameters.map(p => ({
    name: p.name,
    caption: p.caption,
    min: p.min,
    max: p.max,
    current: this.parameters[p.name]
})), null, 2)}

Provide your response as a JSON object with parameter names as keys and suggested values. Consider:
- global_scale: Scale factor based on height, weight, and arm length (typical range 1.0-2.0, where 1.25 is average adult)
- For women, typically use slightly lower scale values (1.0-1.3)
- For men, typically use higher scale values (1.3-1.8)
- Adjust based on arm length if provided
- nominal_clearance: Clearance for fit (0.1-3mm, typically 0.4-0.6mm for good fit)
- print_long_fingers, print_short_fingers, print_finger_phalanx, print_thumb, print_thumb_phalanx: which parts to print
- bearing_pocket_diameter: bearing size if needed (0, 5, 7, 9, 11, 13, or 15mm)
- pin_index: pin style (0=Chicago screws, 1=1/16" pins with bearing, 2=headless, 3=folding)

Return ONLY a valid JSON object, no other text.`;

            const res = await Auth.fetchWithAuth('/api/ai/suggest', {
                method: 'POST',
                body: JSON.stringify({ provider: apiProvider, prompt: promptText }),
            });

            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'AI request failed');

            const aiResponse = data.text;

            // Parse AI response - handle both plain JSON and markdown code blocks
            let suggestions;
            try {
                const jsonMatch = aiResponse.match(/```(?:json)?\s*(\{[\s\S]*?\})\s*```/);
                if (jsonMatch) {
                    suggestions = JSON.parse(jsonMatch[1]);
                } else {
                    suggestions = JSON.parse(aiResponse);
                }
            } catch (e) {
                console.error('Failed to parse AI response:', aiResponse);
                throw new Error('AI response was not valid JSON. Please try again.');
            }

            this.applySuggestions(suggestions);
            this.updateStatus('AI suggestions applied successfully', 'success');

        } catch (error) {
            console.error('AI suggestion error:', error);
            this.updateStatus('Error getting AI suggestions: ' + error.message, 'error');
        } finally {
            this.showLoading(false);
        }
    }

    // ── Saved Configurations ──────────────────────────────────────────────

    setupConfigPanel() {
        const loadBtn = document.getElementById('config-load-btn');
        const saveBtn = document.getElementById('config-save-btn');
        const deleteBtn = document.getElementById('config-delete-btn');

        if (loadBtn) loadBtn.addEventListener('click', () => this.loadSelectedConfig());
        if (saveBtn) saveBtn.addEventListener('click', () => this.saveCurrentConfig());
        if (deleteBtn) deleteBtn.addEventListener('click', () => this.deleteSelectedConfig());
    }

    async loadConfigList() {
        if (!Auth.isAuthenticated()) return;
        const modelFilter = this.currentModel ? `?model_id=${encodeURIComponent(this.currentModel.id)}` : '';
        try {
            const res = await Auth.fetchWithAuth(`/api/configurations${modelFilter}`);
            if (!res.ok) return;
            const configs = await res.json();
            this._configList = configs;

            const select = document.getElementById('saved-config-select');
            if (!select) return;
            select.innerHTML = '<option value="">-- Select saved config --</option>';
            configs.forEach(c => {
                const opt = document.createElement('option');
                opt.value = c.id;
                const owner = c.username !== Auth.getUser()?.username ? ` (${c.username})` : '';
                opt.textContent = `${c.name}${owner}`;
                select.appendChild(opt);
            });
        } catch (err) {
            console.error('Failed to load config list:', err);
        }
    }

    async loadSelectedConfig() {
        const select = document.getElementById('saved-config-select');
        const id = select?.value;
        if (!id) { this.updateStatus('Select a configuration to load', 'error'); return; }

        try {
            const res = await Auth.fetchWithAuth(`/api/configurations/${id}`);
            const config = await res.json();
            if (!res.ok) throw new Error(config.error || 'Load failed');

            // Switch to the right model if needed
            if (!this.currentModel || this.currentModel.id !== config.model_id) {
                const modelSelect = document.getElementById('model-select');
                if (modelSelect) modelSelect.value = config.model_id;
                await this.loadModel(config.model_id);
            }

            this.applySuggestions(config.parameters);

            // Populate name/notes fields
            const nameEl = document.getElementById('config-name');
            const notesEl = document.getElementById('config-notes');
            if (nameEl) nameEl.value = config.name;
            if (notesEl) notesEl.value = config.notes || '';

            this._currentConfigId = config.id;
            this.updateStatus(`Loaded config: ${config.name}`, 'success');
        } catch (err) {
            this.updateStatus('Error loading config: ' + err.message, 'error');
        }
    }

    async saveCurrentConfig() {
        if (!this.currentModel) { this.updateStatus('Select a model first', 'error'); return; }
        if (!Auth.isAuthenticated()) { this.updateStatus('Please log in to save', 'error'); return; }

        const nameEl = document.getElementById('config-name');
        const notesEl = document.getElementById('config-notes');
        const name = nameEl?.value.trim();
        const notes = notesEl?.value.trim() || '';

        if (!name) { this.updateStatus('Enter a name for the configuration', 'error'); return; }

        const body = {
            model_id: this.currentModel.id,
            name,
            parameters: { ...this.parameters },
            notes,
        };

        try {
            // If we have a current config selected and name matches, update; otherwise create new
            const select = document.getElementById('saved-config-select');
            const selectedId = select?.value;
            const currentConfig = this._configList?.find(c => String(c.id) === selectedId);
            const shouldUpdate = currentConfig && currentConfig.name === name;

            let res;
            if (shouldUpdate) {
                res = await Auth.fetchWithAuth(`/api/configurations/${currentConfig.id}`, {
                    method: 'PATCH',
                    body: JSON.stringify({ parameters: body.parameters, notes: body.notes }),
                });
            } else {
                res = await Auth.fetchWithAuth('/api/configurations', {
                    method: 'POST',
                    body: JSON.stringify(body),
                });
            }

            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'Save failed');

            await this.loadConfigList();

            // Select the saved config
            if (select) select.value = data.id;
            this._currentConfigId = data.id;

            this.updateStatus(`Config "${name}" saved`, 'success');
        } catch (err) {
            this.updateStatus('Error saving config: ' + err.message, 'error');
        }
    }

    async deleteSelectedConfig() {
        const select = document.getElementById('saved-config-select');
        const id = select?.value;
        if (!id) { this.updateStatus('Select a configuration to delete', 'error'); return; }

        if (!confirm('Delete this saved configuration?')) return;

        try {
            const res = await Auth.fetchWithAuth(`/api/configurations/${id}`, { method: 'DELETE' });
            const data = await res.json();
            if (!res.ok) throw new Error(data.error || 'Delete failed');

            this._currentConfigId = null;
            const nameEl = document.getElementById('config-name');
            const notesEl = document.getElementById('config-notes');
            if (nameEl) nameEl.value = '';
            if (notesEl) notesEl.value = '';

            await this.loadConfigList();
            this.updateStatus('Configuration deleted', 'success');
        } catch (err) {
            this.updateStatus('Error deleting config: ' + err.message, 'error');
        }
    }

    applySuggestions(suggestions) {
        // Apply suggested values to parameters
        for (const [paramName, value] of Object.entries(suggestions)) {
            if (this.parameters.hasOwnProperty(paramName)) {
                this.parameters[paramName] = value;

                // Update UI controls
                const input = document.getElementById(`param-${paramName}`);
                if (input) {
                    if (input.type === 'checkbox') {
                        input.checked = value;
                    } else {
                        input.value = value;
                    }
                }

                // Update value display
                const valueDisplay = document.getElementById(`value-${paramName}`);
                if (valueDisplay) {
                    valueDisplay.textContent = value;
                }
            }
        }

        // Update editor and render
        this.updateEditor();
        this.renderPreview();
    }

    applyGeometryParameters(geomParams) {
        if (!this.currentModel || !geomParams) return;

        const mapping = {
            global_scale: 'global_scale',
            clearance_mm: 'nominal_clearance',
        };

        const resolved = {};
        for (const [src, dst] of Object.entries(mapping)) {
            if (geomParams[src] !== undefined) resolved[dst] = geomParams[src];
        }
        for (const [key, val] of Object.entries(geomParams)) {
            if (this.parameters.hasOwnProperty(key)) resolved[key] = val;
        }

        this.applySuggestions(resolved);
        this.updateStatus('Anthropometric parameters applied', 'success');
    }
}

// Initialize the application when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    window.parameterEditor = new ParameterEditor();
});
