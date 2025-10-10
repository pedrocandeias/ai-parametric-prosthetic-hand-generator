// OpenSCAD Parameter Editor Application
class ParameterEditor {
    constructor() {
        this.config = null;
        this.currentModel = null;
        this.parameters = {};
        this.originalCode = '';

        this.init();
    }

    async init() {
        // Load configuration
        await this.loadConfiguration();

        // Setup event listeners
        this.setupEventListeners();

        // Populate model selector
        this.populateModelSelector();
    }

    async loadConfiguration() {
        try {
            const response = await fetch('../models/models-config.json');
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

        // Initialize parameters with default values
        model.parameters.forEach(param => {
            this.parameters[param.name] = param.initial;
        });

        // Load OpenSCAD file
        try {
            const response = await fetch(`../models/${model.file}`);
            this.originalCode = await response.text();

            // Display model info
            this.displayModelInfo(model);

            // Generate parameter controls
            this.generateParameterControls(model.parameters);

            // Update editor
            this.updateEditor();

            this.updateStatus(`Loaded model: ${model.name}`, 'success');
        } catch (error) {
            this.updateStatus('Error loading model file: ' + error.message, 'error');
            console.error('Error loading model:', error);
        }
    }

    clearModel() {
        this.currentModel = null;
        this.parameters = {};
        this.originalCode = '';

        document.getElementById('model-info').style.display = 'none';
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

    generateParameterControl(param) {
        const value = this.parameters[param.name];

        let controlHtml = '';

        if (param.type === 'boolean') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${param.name}</span>
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
                            <span class="param-name">${param.name}</span>
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
                            <span class="param-name">${param.name}</span>
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
        } else if (param.type === 'string') {
            controlHtml = `
                <div class="param-item">
                    <div class="param-label">
                        <span class="param-name">${param.name}</span>
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
    }

    updateEditor() {
        if (!this.currentModel) return;

        let code = this.originalCode;

        // Replace parameter values in the code
        // Look for parameter declarations in comments like /* [Group] */ followed by parameter = value;
        this.currentModel.parameters.forEach(param => {
            const paramValue = this.parameters[param.name];

            // Try to find and replace the parameter assignment
            // Patterns: "paramName = value;" with any whitespace
            const patterns = [
                new RegExp(`(${param.name}\\s*=\\s*)[^;]+;`, 'g'),
                new RegExp(`(${param.name}\\s*=\\s*)[^\\n]+`, 'g')
            ];

            for (const pattern of patterns) {
                if (code.match(pattern)) {
                    code = code.replace(pattern, `$1${paramValue};`);
                    break;
                }
            }
        });

        document.getElementById('editor').value = code;
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
        this.updateStatus('Parameters reset to defaults', 'success');
    }

    renderPreview() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }

        // This is a placeholder - in a real implementation, you would:
        // 1. Send the code to an OpenSCAD renderer (backend or WASM)
        // 2. Display the result in the viewer iframe

        this.updateStatus('Rendering preview... (OpenSCAD integration needed)', 'success');

        // For demonstration, show the code would be sent to OpenSCAD
        console.log('Code to render:', document.getElementById('editor').value);

        alert('Preview rendering requires OpenSCAD WASM integration from openscad-playground.\n\nThe code has been updated in the editor with your parameters.\n\nTo complete this feature, integrate the openscad-playground WebAssembly renderer.');
    }

    exportSTL() {
        if (!this.currentModel) {
            this.updateStatus('No model selected', 'error');
            return;
        }

        // This is a placeholder - in a real implementation, you would:
        // 1. Render the model with OpenSCAD
        // 2. Export as STL
        // 3. Download the file

        const code = document.getElementById('editor').value;
        const blob = new Blob([code], { type: 'text/plain' });
        const url = URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `${this.currentModel.id}_${Date.now()}.scad`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);

        this.updateStatus('OpenSCAD file downloaded (STL export requires OpenSCAD renderer)', 'success');
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
}

// Initialize the application when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
    new ParameterEditor();
});
