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

        // Dependency system
        this.autoLink = true;
        this.dependencyGraph = {};
        this.dependentParams = new Set();
        this.validationWarnings = [];

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

        // Build dependency graph
        this.buildDependencyGraph(model.parameters);

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
        const aiEmpty = document.getElementById('ai-empty-state');
        if (aiEmpty) aiEmpty.style.display = 'block';
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
        const aiEmpty = document.getElementById('ai-empty-state');
        if (aiEmpty) aiEmpty.style.display = 'none';
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
            html += `<div class="param-group">`;

            // Add auto-link toggle to Anthropometric group
            if (groupName === 'Anthropometric') {
                html += `
                    <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                        <h3>${groupName}</h3>
                        <label class="auto-link-toggle">
                            <input type="checkbox" id="auto-link" ${this.autoLink ? 'checked' : ''}>
                            <span>Auto-link</span>
                        </label>
                    </div>
                `;
            } else {
                html += `<h3>${groupName}</h3>`;
            }

            params.forEach(param => {
                html += this.generateParameterControl(param);
            });

            html += '</div>';
        }

        // Add warnings area
        html += '<div id="param-warnings"></div>';

        container.innerHTML = html;

        // Wire auto-link toggle
        const autoLinkCheckbox = document.getElementById('auto-link');
        if (autoLinkCheckbox) {
            autoLinkCheckbox.addEventListener('change', (e) => {
                this.autoLink = e.target.checked;
            });
        }

        // Add event listeners to parameter controls
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

        // Initial validation display
        this.validateParameters();
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
        const linkIndicator = param.dependsOn ? `<span class="param-dep-indicator" title="Driven by ${this.formatParamName(param.dependsOn)}">⇠</span>` : '';

        let controlHtml = '';

        if (param.type === 'boolean') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${label}${linkIndicator}</span>
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
                            <span class="param-name">${label}${linkIndicator}</span>
                            <span class="param-value" id="value-${param.name}">${value}</span>
                        </div>
                        <div class="param-caption">${param.caption}</div>
                        <input type="range"
                               id="param-${param.name}"
                               class="param-control"
                               min="${param.min}"
                               max="${param.max}"
                               step="${param.step || 1}"
                               value="${value}"
                               style="--range-pct: ${((value - param.min) / (param.max - param.min) * 100).toFixed(1)}%">
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
                            <span class="param-name">${label}${linkIndicator}</span>
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
                        <span class="param-name">${label}${linkIndicator}</span>
                    </div>
                    <div class="param-caption">${param.caption}</div>
                    <select id="param-${param.name}" class="param-control">${options}</select>
                </div>
            `;
        } else if (param.type === 'string') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${label}${linkIndicator}</span>
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

    buildDependencyGraph(parameters) {
        this.dependencyGraph = {};
        this.dependentParams.clear();

        parameters.forEach(param => {
            if (param.drives && param.drives.length > 0) {
                this.dependencyGraph[param.name] = param.drives;
            }
            if (param.dependsOn) {
                this.dependentParams.add(param.name);
            }
        });
    }

    setParameterValue(name, value) {
        this.parameters[name] = value;

        const input = document.getElementById(`param-${name}`);
        if (input) {
            if (input.type === 'checkbox') {
                input.checked = value;
            } else {
                input.value = value;
            }

            if (input.type === 'range') {
                const pct = ((value - parseFloat(input.min)) / (parseFloat(input.max) - parseFloat(input.min))) * 100;
                input.style.setProperty('--range-pct', `${pct}%`);
            }
        }

        const valueDisplay = document.getElementById(`value-${name}`);
        if (valueDisplay) {
            valueDisplay.textContent = value;
        }
    }

    validateParameters() {
        this.validationWarnings = [];

        if (!this.currentModel) return this.validationWarnings;

        this.currentModel.parameters.forEach(param => {
            const val = this.parameters[param.name];

            // Bounds checking
            if (param.type === 'number') {
                if (param.min !== undefined && val < param.min) {
                    this.validationWarnings.push(`${this.formatParamName(param.name)}: ${val} is below minimum ${param.min}`);
                }
                if (param.max !== undefined && val > param.max) {
                    this.validationWarnings.push(`${this.formatParamName(param.name)}: ${val} exceeds maximum ${param.max}`);
                }
            }

            // Ratio checking (advisory only)
            if (param.dependsOn && param.ratio) {
                const sourceVal = this.parameters[param.dependsOn];
                if (sourceVal && typeof sourceVal === 'number') {
                    const expectedVal = sourceVal * param.ratio;
                    const deviation = Math.abs(val - expectedVal) / expectedVal;
                    if (deviation > 0.30) {
                        const percentOff = Math.round(deviation * 100);
                        this.validationWarnings.push(`${this.formatParamName(param.name)}: ${percentOff}% off typical ratio to ${this.formatParamName(param.dependsOn)}`);
                    }
                }
            }
        });

        this.showValidationWarnings();
        return this.validationWarnings;
    }

    showValidationWarnings() {
        const warningsDiv = document.getElementById('param-warnings');
        if (!warningsDiv) return;

        if (this.validationWarnings.length === 0) {
            warningsDiv.innerHTML = '';
            return;
        }

        let html = this.validationWarnings.map(w =>
            `<p class="param-warning">⚠️ ${w}</p>`
        ).join('');
        warningsDiv.innerHTML = html;
    }

    updateParameter(paramName, input) {
        let value;

        if (input.type === 'checkbox') {
            value = input.checked;
        } else if (input.type === 'number' || input.type === 'range') {
            value = parseFloat(input.value);
        } else if (input.type === 'select-one') {
            const raw = input.value;
            if (raw === 'true')  value = true;
            else if (raw === 'false') value = false;
            else if (!isNaN(raw) && raw !== '') value = parseFloat(raw);
            else value = raw;
        } else {
            value = input.value;
        }

        // Find param definition for bounds checking
        const paramDef = this.currentModel?.parameters.find(p => p.name === paramName);
        if (paramDef && paramDef.type === 'number') {
            if (paramDef.min !== undefined) value = Math.max(paramDef.min, value);
            if (paramDef.max !== undefined) value = Math.min(paramDef.max, value);
        }

        this.setParameterValue(paramName, value);

        // Handle auto-link cascade: update any parameters that depend on this one
        if (this.autoLink && this.dependencyGraph[paramName]) {
            this.dependencyGraph[paramName].forEach(dep => {
                const drivenParamDef = this.currentModel?.parameters.find(p => p.name === dep.param);
                if (drivenParamDef) {
                    let newVal = value * dep.ratio;
                    if (drivenParamDef.min !== undefined) newVal = Math.max(drivenParamDef.min, newVal);
                    if (drivenParamDef.max !== undefined) newVal = Math.min(drivenParamDef.max, newVal);
                    this.setParameterValue(dep.param, newVal);

                    // Flash indicator
                    const control = document.getElementById(`param-${dep.param}`);
                    if (control) {
                        control.classList.add('auto-updated');
                        setTimeout(() => control.classList.remove('auto-updated'), 300);
                    }
                }
            });
        }

        // Update editor
        this.updateEditor();

        // Validate and show warnings
        this.validateParameters();

        // Auto-render on parameter change with debouncing
        clearTimeout(this.renderTimeout);
        this.renderTimeout = setTimeout(() => {
            this.renderPreview();
        }, 1500);
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
                console.log('OFF data length:', offData?.length);

                // Parse colored OFF (COFF) and convert to multi-material GLB
                const offText = new TextDecoder().decode(offData);
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

    // ── 3MF → GLB pipeline ────────────────────────────────────────────────────

    // Extract 3D/3dmodel.model XML from a 3MF ZIP (Uint8Array).
    // Handles ZIP64 entries where compSize in the local header is 0xFFFFFFFF
    // and the real size lives in the ZIP64 extra field (header ID 0x0001).
    async extract3MFXml(zipBytes) {
        const view = new DataView(zipBytes.buffer, zipBytes.byteOffset, zipBytes.byteLength);
        let pos = 0;
        while (pos <= zipBytes.byteLength - 30) {
            if (view.getUint32(pos, true) !== 0x04034b50) { pos++; continue; }
            const compMethod = view.getUint16(pos +  8, true);
            let   compSize   = view.getUint32(pos + 18, true);
            const fnameLen   = view.getUint16(pos + 26, true);
            const extraLen   = view.getUint16(pos + 28, true);
            const fname = new TextDecoder().decode(zipBytes.subarray(pos + 30, pos + 30 + fnameLen));

            // ZIP64: real sizes are in the extra field when the standard field is 0xFFFFFFFF
            if (compSize === 0xFFFFFFFF) {
                const extraStart = pos + 30 + fnameLen;
                let ep = extraStart;
                while (ep + 4 <= extraStart + extraLen) {
                    const hdrId  = view.getUint16(ep, true);
                    const blkSz  = view.getUint16(ep + 2, true);
                    if (hdrId === 0x0001 && blkSz >= 16) {
                        // 8 bytes original size, 8 bytes compressed size
                        compSize = Number(view.getBigUint64(ep + 12, true));
                        break;
                    }
                    ep += 4 + blkSz;
                }
            }

            const dataStart = pos + 30 + fnameLen + extraLen;
            if (fname === '3D/3dmodel.model') {
                const compData = zipBytes.subarray(dataStart, dataStart + compSize);
                if (compMethod === 0) return new TextDecoder().decode(compData);
                // deflate-raw (method 8)
                const ds = new DecompressionStream('deflate-raw');
                const writer = ds.writable.getWriter();
                writer.write(compData.slice());
                writer.close();
                const reader = ds.readable.getReader();
                const chunks = [];
                for (;;) {
                    const { value, done } = await reader.read();
                    if (done) break;
                    chunks.push(value);
                }
                const total = chunks.reduce((s, c) => s + c.length, 0);
                const out = new Uint8Array(total);
                let off = 0;
                for (const c of chunks) { out.set(c, off); off += c.length; }
                return new TextDecoder().decode(out);
            }
            pos = dataStart + (compSize > 0 ? compSize : 1);
        }
        throw new Error('3D/3dmodel.model not found in 3MF archive');
    }

    // Parse 3MF ZIP bytes and return a multi-material GLB Blob
    async convert3MFtoGLB(zipBytes) {
        const xml = await this.extract3MFXml(zipBytes);
        const doc = new DOMParser().parseFromString(xml, 'text/xml');

        // ── Materials ──────────────────────────────────────────────────────────
        const materials = [];
        for (const base of doc.getElementsByTagName('base')) {
            const hex = (base.getAttribute('displaycolor') || '#CCCCCCFF');
            materials.push({
                r: parseInt(hex.slice(1, 3), 16) / 255,
                g: parseInt(hex.slice(3, 5), 16) / 255,
                b: parseInt(hex.slice(5, 7), 16) / 255,
                a: hex.length >= 9 ? parseInt(hex.slice(7, 9), 16) / 255 : 1.0,
            });
        }
        if (!materials.length) materials.push({ r: 0.75, g: 0.75, b: 0.75, a: 1.0 });

        // ── Vertices ───────────────────────────────────────────────────────────
        const vertEls = doc.getElementsByTagName('vertex');
        const verts = new Float32Array(vertEls.length * 3);
        let vi = 0;
        for (const v of vertEls) {
            verts[vi++] = parseFloat(v.getAttribute('x'));
            verts[vi++] = parseFloat(v.getAttribute('y'));
            verts[vi++] = parseFloat(v.getAttribute('z'));
        }

        // ── Triangles grouped by material index ────────────────────────────────
        const objEl = doc.getElementsByTagName('object')[0];
        const defaultMat = parseInt(objEl?.getAttribute('pindex') || '0');
        const trisByMat = new Map();
        for (const tri of doc.getElementsByTagName('triangle')) {
            const mi = tri.hasAttribute('p1') ? parseInt(tri.getAttribute('p1')) : defaultMat;
            if (!trisByMat.has(mi)) trisByMat.set(mi, []);
            const g = trisByMat.get(mi);
            g.push(parseInt(tri.getAttribute('v1')),
                   parseInt(tri.getAttribute('v2')),
                   parseInt(tri.getAttribute('v3')));
        }

        return this.createMultiMaterialGLB(verts, trisByMat, materials);
    }

    // Build a GLB with one primitive per color group
    createMultiMaterialGLB(verts, trisByMat, materials) {
        // ── Vertex bounds ──────────────────────────────────────────────────────
        let minX = Infinity, minY = Infinity, minZ = Infinity;
        let maxX = -Infinity, maxY = -Infinity, maxZ = -Infinity;
        for (let i = 0; i < verts.length; i += 3) {
            if (verts[i]   < minX) minX = verts[i];   if (verts[i]   > maxX) maxX = verts[i];
            if (verts[i+1] < minY) minY = verts[i+1]; if (verts[i+1] > maxY) maxY = verts[i+1];
            if (verts[i+2] < minZ) minZ = verts[i+2]; if (verts[i+2] > maxZ) maxZ = verts[i+2];
        }

        // ── Pack binary: [vertices] [idx0] [idx1] ... ─────────────────────────
        const matKeys = [...trisByMat.keys()];
        const idxArrays = matKeys.map(k => new Uint32Array(trisByMat.get(k)));
        const idxTotalBytes = idxArrays.reduce((s, a) => s + a.byteLength, 0);
        const binData = new Uint8Array(verts.byteLength + idxTotalBytes);
        binData.set(new Uint8Array(verts.buffer, verts.byteOffset, verts.byteLength), 0);
        const idxOffsets = [];
        let bOff = verts.byteLength;
        for (const arr of idxArrays) {
            idxOffsets.push(bOff);
            binData.set(new Uint8Array(arr.buffer), bOff);
            bOff += arr.byteLength;
        }

        // ── glTF JSON ──────────────────────────────────────────────────────────
        const bufferViews = [
            { buffer: 0, byteOffset: 0, byteLength: verts.byteLength, target: 34962 },
            ...idxArrays.map((arr, i) => ({
                buffer: 0, byteOffset: idxOffsets[i], byteLength: arr.byteLength, target: 34963
            }))
        ];
        const accessors = [
            {
                bufferView: 0, byteOffset: 0, componentType: 5126,
                count: verts.length / 3, type: 'VEC3',
                max: [maxX, maxY, maxZ], min: [minX, minY, minZ]
            },
            ...idxArrays.map((arr, i) => ({
                bufferView: i + 1, byteOffset: 0, componentType: 5125,
                count: arr.length, type: 'SCALAR'
            }))
        ];
        const gltfMaterials = matKeys.map(mi => {
            const m = materials[mi] || { r: 0.75, g: 0.75, b: 0.75, a: 1.0 };
            return {
                pbrMetallicRoughness: {
                    baseColorFactor: [m.r, m.g, m.b, m.a],
                    metallicFactor: 0.0,
                    roughnessFactor: 0.75
                },
                doubleSided: true,
                alphaMode: m.a < 1.0 ? 'BLEND' : 'OPAQUE'
            };
        });
        const primitives = matKeys.map((_, i) => ({
            attributes: { POSITION: 0 }, indices: i + 1, material: i
        }));

        const scene = {
            asset: { version: '2.0', generator: 'Prosthetic Hand AI' },
            scene: 0,
            scenes: [{ nodes: [0] }],
            nodes: [{ mesh: 0 }],
            meshes: [{ primitives }],
            materials: gltfMaterials,
            buffers: [{ byteLength: binData.byteLength }],
            bufferViews,
            accessors
        };

        // ── Pack GLB ───────────────────────────────────────────────────────────
        const jsonBuf = new TextEncoder().encode(JSON.stringify(scene));
        const jsonPad = (4 - (jsonBuf.length % 4)) % 4;
        const binPad  = (4 - (binData.length  % 4)) % 4;
        const totalLen = 12 + 8 + jsonBuf.length + jsonPad + 8 + binData.length + binPad;

        const glb = new ArrayBuffer(totalLen);
        const dv = new DataView(glb);
        let p = 0;
        dv.setUint32(p, 0x46546C67, true); p += 4;   // 'glTF'
        dv.setUint32(p, 2, true); p += 4;
        dv.setUint32(p, totalLen, true); p += 4;
        // JSON chunk
        dv.setUint32(p, jsonBuf.length + jsonPad, true); p += 4;
        dv.setUint32(p, 0x4E4F534A, true); p += 4;   // 'JSON'
        new Uint8Array(glb, p).set(jsonBuf); p += jsonBuf.length;
        new Uint8Array(glb, p).fill(0x20, 0, jsonPad); p += jsonPad;
        // BIN chunk
        dv.setUint32(p, binData.length + binPad, true); p += 4;
        dv.setUint32(p, 0x004E4942, true); p += 4;   // 'BIN\0'
        new Uint8Array(glb, p).set(binData); p += binData.length;
        new Uint8Array(glb, p).fill(0, 0, binPad);

        return new Blob([glb], { type: 'model/gltf-binary' });
    }

    // Parse OFF/COFF and convert to a (possibly multi-material) GLB.
    // When OpenSCAD exports colored geometry it appends per-face RGB integers
    // after the vertex indices: "3 v1 v2 v3 R G B" (values 0–255).
    async convertOFFtoGLB(offText) {
        const lines = offText.split('\n').map(l => l.trim()).filter(l => l && !l.startsWith('#'));

        let currentLine = 0;
        let counts;

        // Handle OFF / COFF header
        if (lines[0].match(/^C?OFF(\s|$)/)) {
            counts = lines[0].replace(/^C?OFF\s*/, '').trim();
            currentLine = 1;
        }
        if (!counts) {
            counts = lines[currentLine++];
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

        // Parse faces — COFF appends R G B (0–255) or R G B A after vertex indices
        const trisByColor = new Map();  // "R,G,B,A" → [v0,v1,v2, ...]
        for (let i = 0; i < numFaces; i++) {
            const parts = lines[currentLine + i].split(/\s+/).map(Number);
            const n = parts[0];
            const faceVerts = parts.slice(1, n + 1);

            // Color key from trailing RGBA integers (0–255); default to grey
            let colorKey = 'default';
            if (parts.length > n + 1) {
                const r = parts[n + 1], g = parts[n + 2], b = parts[n + 3];
                const a = parts.length > n + 4 ? parts[n + 4] : 255;
                colorKey = `${r},${g},${b},${a}`;
            }
            if (!trisByColor.has(colorKey)) trisByColor.set(colorKey, []);
            const bucket = trisByColor.get(colorKey);
            for (let j = 1; j < faceVerts.length - 1; j++) {
                bucket.push(faceVerts[0], faceVerts[j], faceVerts[j + 1]);
            }
        }

        console.log(`COFF color groups: ${trisByColor.size}, vertices: ${vertices.length / 3}`);

        // Build materials from color keys
        const matKeys = [...trisByColor.keys()];
        const materials = matKeys.map(k => {
            if (k === 'default') return { r: 0.75, g: 0.75, b: 0.75, a: 1.0 };
            const [r, g, b, a] = k.split(',').map(Number);
            return { r: r/255, g: g/255, b: b/255, a: a/255 };
        });
        const indexMap = new Map(matKeys.map((k, i) => [k, i]));
        const trisByMatIdx = new Map(matKeys.map((k, i) => [i, trisByColor.get(k)]));

        return this.createMultiMaterialGLB(new Float32Array(vertices), trisByMatIdx, materials);
    }

    // Create a minimal single-material GLB (legacy path, unused by preview)
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

    // Entry point for the Export STL button. Models that declare printable `parts`
    // open a selection modal; others export the whole model as a single file.
    exportSTL() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }
        if (Array.isArray(this.currentModel.parts) && this.currentModel.parts.length) {
            this.openExportModal();
        } else {
            this.runExport([{ id: 'combined', name: 'Whole model', combined: true }]);
        }
    }

    openExportModal() {
        const modal = document.getElementById('export-modal');
        const list = document.getElementById('export-items');
        const status = document.getElementById('export-status');
        if (!modal || !list) {
            this.runExport([{ id: 'combined', name: 'Whole model', combined: true }]);
            return;
        }
        status.textContent = '';

        // A "combined" option plus one row per declared printable part.
        const items = [
            { id: 'combined', name: 'Whole model (single file)', combined: true },
            ...this.currentModel.parts.map(p => ({ id: p.id, name: p.name })),
        ];
        list.innerHTML = items.map(it => `
            <label class="export-row">
                <input type="checkbox" class="export-item" value="${it.id}" ${it.combined ? '' : 'checked'}>
                ${it.name}
            </label>`).join('');

        const checkboxes = () => Array.from(list.querySelectorAll('.export-item'));
        const selectAll = document.getElementById('export-select-all');
        selectAll.checked = checkboxes().every(c => c.checked);
        selectAll.onchange = () => checkboxes().forEach(c => { c.checked = selectAll.checked; });
        list.onchange = () => { selectAll.checked = checkboxes().every(c => c.checked); };

        const close = () => this.closeExportModal();
        document.getElementById('export-close-btn').onclick = close;
        document.getElementById('export-cancel-btn').onclick = close;
        modal.onclick = (e) => { if (e.target === modal) close(); };

        document.getElementById('export-confirm-btn').onclick = () => {
            const selected = checkboxes().filter(c => c.checked).map(c => c.value);
            if (!selected.length) { status.textContent = 'Select at least one item.'; return; }
            const selections = selected.map(id => id === 'combined'
                ? { id: 'combined', name: 'Whole model', combined: true }
                : this.currentModel.parts.find(p => p.id === id));
            this.closeExportModal();
            this.runExport(selections);
        };

        modal.classList.add('active');
    }

    closeExportModal() {
        const modal = document.getElementById('export-modal');
        if (modal) modal.classList.remove('active');
    }

    // Render and download one STL per selection. A single selection downloads
    // directly; multiple selections are bundled into a ZIP.
    async runExport(selections) {
        if (!this.currentModel) return;
        const baseCode = document.getElementById('editor').value;
        this.showLoading(true);

        try {
            const files = [];
            for (let i = 0; i < selections.length; i++) {
                const sel = selections[i];
                this.updateStatus(`Exporting ${sel.name}… (${i + 1}/${selections.length})`, '');
                const code = sel.combined ? baseCode : this._buildPartCode(baseCode, sel);
                const data = await this._renderStlFromCode(code);
                files.push({ name: `${this.currentModel.id}_${sel.id}.stl`, data });
            }

            if (files.length === 1) {
                this._downloadBlob(new Blob([files[0].data], { type: 'model/stl' }), files[0].name);
            } else {
                const zip = this._zipStore(files);
                this._downloadBlob(new Blob([zip], { type: 'application/zip' }),
                    `${this.currentModel.id}_parts_${Date.now()}.zip`);
            }
            this.updateStatus(`Exported ${files.length} STL file${files.length > 1 ? 's' : ''}`, 'success');
        } catch (error) {
            this.updateStatus('Export error: ' + error.message, 'error');
            console.error('Export error:', error);
        } finally {
            this.showLoading(false);
        }
    }

    // Append overrides that isolate a single part: enable this part's toggles and
    // disable every other part's toggles. OpenSCAD honours the last assignment.
    _buildPartCode(baseCode, part) {
        const allToggles = new Set();
        for (const p of this.currentModel.parts) (p.toggles || []).forEach(t => allToggles.add(t));
        const on = new Set(part.toggles || []);
        const lines = Array.from(allToggles).map(t => `${t} = ${on.has(t) ? 'true' : 'false'};`);
        return `${baseCode}\n\n// -- per-part export override (${part.id}) --\n${lines.join('\n')}\n`;
    }

    // Render SCAD source to a binary-STL Uint8Array via a one-shot worker.
    _renderStlFromCode(code) {
        return new Promise((resolve, reject) => {
            const worker = new Worker('openscad-worker.js');
            const timeout = setTimeout(() => { worker.terminate(); reject(new Error('Export timeout')); }, 120000);

            const backendFlag = (this.currentModel && this.currentModel.renderBackend !== undefined)
                ? this.currentModel.renderBackend : 'manifold';
            const backendArgs = backendFlag ? ['--backend', backendFlag] : [];
            const useArchiveLibraries = !!(this.currentModel && this.currentModel.mountArchives);

            worker.onmessage = (e) => {
                if (!e.data.result) return;
                clearTimeout(timeout);
                const result = e.data.result;
                worker.terminate();
                if (result.outputs && result.outputs.length > 0) {
                    resolve(result.outputs[0][1]); // Uint8Array, NOT base64
                } else {
                    const errMsg = result.error || (result.mergedOutputs || [])
                        .filter(m => m.stderr || m.error).map(m => m.stderr || m.error).join(' ')
                        || 'No output generated';
                    reject(new Error(String(errMsg).substring(0, 160)));
                }
            };
            worker.onerror = (err) => { clearTimeout(timeout); worker.terminate(); reject(err); };

            worker.postMessage({
                inputs: [{ path: '/input.scad', content: code }, ...(this.dependencyFiles || [])],
                args: ['/input.scad', '-o', '/output.stl', '--export-format', 'binstl', ...backendArgs],
                outputPaths: ['/output.stl'],
                mountArchives: useArchiveLibraries,
            });
        });
    }

    _downloadBlob(blob, filename) {
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = filename;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
    }

    // Minimal store-only (uncompressed) ZIP writer — bundles STLs without a
    // third-party dependency.
    _zipStore(files) {
        const enc = new TextEncoder();
        const chunks = [];
        const central = [];
        let offset = 0;

        const u16 = (v) => new Uint8Array([v & 0xff, (v >> 8) & 0xff]);
        const u32 = (v) => new Uint8Array([v & 0xff, (v >> 8) & 0xff, (v >> 16) & 0xff, (v >>> 24) & 0xff]);
        const push = (arr) => { chunks.push(arr); offset += arr.length; };

        for (const f of files) {
            const nameBytes = enc.encode(f.name);
            const data = f.data;
            const crc = this._crc32(data);
            const localOffset = offset;

            // Local file header
            push(u32(0x04034b50));
            push(u16(20)); push(u16(0)); push(u16(0));        // version, flags, method (store)
            push(u16(0)); push(u16(0));                       // mod time, date
            push(u32(crc)); push(u32(data.length)); push(u32(data.length));
            push(u16(nameBytes.length)); push(u16(0));        // name len, extra len
            push(nameBytes);
            push(data);

            // Central directory record (written after all files)
            const c = [];
            const cp = (a) => c.push(a);
            cp(u32(0x02014b50));
            cp(u16(20)); cp(u16(20)); cp(u16(0)); cp(u16(0)); // ver made, ver needed, flags, method
            cp(u16(0)); cp(u16(0));                           // time, date
            cp(u32(crc)); cp(u32(data.length)); cp(u32(data.length));
            cp(u16(nameBytes.length)); cp(u16(0)); cp(u16(0)); // name, extra, comment len
            cp(u16(0)); cp(u16(0)); cp(u32(0));               // disk#, int attrs, ext attrs
            cp(u32(localOffset));
            cp(nameBytes);
            central.push(c);
        }

        const cdStart = offset;
        for (const c of central) for (const a of c) push(a);
        const cdSize = offset - cdStart;

        // End of central directory
        push(u32(0x06054b50));
        push(u16(0)); push(u16(0));
        push(u16(files.length)); push(u16(files.length));
        push(u32(cdSize)); push(u32(cdStart));
        push(u16(0));

        const total = chunks.reduce((n, a) => n + a.length, 0);
        const out = new Uint8Array(total);
        let pos = 0;
        for (const a of chunks) { out.set(a, pos); pos += a.length; }
        return out;
    }

    _crc32(buf) {
        let table = this._crcTable;
        if (!table) {
            table = new Uint32Array(256);
            for (let n = 0; n < 256; n++) {
                let c = n;
                for (let k = 0; k < 8; k++) c = (c & 1) ? (0xedb88320 ^ (c >>> 1)) : (c >>> 1);
                table[n] = c >>> 0;
            }
            this._crcTable = table;
        }
        let crc = 0xffffffff;
        for (let i = 0; i < buf.length; i++) crc = (crc >>> 8) ^ table[(crc ^ buf[i]) & 0xff];
        return (crc ^ 0xffffffff) >>> 0;
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
            const promptText = `You are sizing a 3D-printed parametric prosthetic hand model ("${this.currentModel.name}") for a patient.

Patient anthropometric data:
${anthropometricInput}

These are the model's adjustable parameters. Each has a name, a caption describing what it controls, an allowed range (min/max where applicable), and the current value:
${JSON.stringify(this.currentModel.parameters.map(p => ({
    name: p.name,
    caption: p.caption,
    type: p.type,
    min: p.min,
    max: p.max,
    current: this.parameters[p.name]
})), null, 2)}

Guidance:
- Anthropometric parameters are anatomical measurements in millimetres. Use the patient's data to set them directly. Canonical fields (when present): palm_breadth_mm (knuckle-to-knuckle, ~70-100mm adult), palm_length_mm (wrist to MCP, ~90-120mm), palm_thickness_mm (~22-38mm), index/middle/ring/pinky_finger_length_mm (MCP crease to tip), thumb_length_mm, gauntlet_width_mm (≈ wrist circumference / π + ~5mm clearance).
- If the data is qualitative (e.g. "woman, 172cm, slim build"), estimate plausible adult measurements from population norms; women typically run smaller than men.
- Keep proportions realistic relative to each other (e.g. middle finger longest, pinky shortest).
- Only suggest values for parameters listed above, by their exact name, and stay within each parameter's min/max.
- Leave hardware/visibility/color parameters at their current values unless the patient data clearly implies a change.

Respond with ONLY a valid JSON object mapping parameter names to suggested values. No prose, no markdown.`;

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
