document.addEventListener('DOMContentLoaded', () => {
    const WS_URL = `ws://${window.location.host}/ws/commands`;
    let socket;
    let fullTfConfig = {}; // Store the full TF config globally

    // --- Element References ---
    const socketStatusEl = document.getElementById('socket-status');
    const socketStatusIndicatorEl = document.getElementById('socket-status-indicator');
    const currentContextEl = document.getElementById('current-context');
    const newContextInput = document.getElementById('new-context-input');
    const setContextBtn = document.getElementById('set-context-btn');
    const kubeContextSelect = document.getElementById('kube-context-select');
    const bootstrapBtn = document.getElementById('bootstrap-btn');
    const logOutputEl = document.getElementById('log-output');
    const clearLogBtn = document.getElementById('clear-log-btn');
    const nodesListEl = document.getElementById('nodes-list');
    const refreshNodesBtn = document.getElementById('refresh-nodes-btn');
    const tfClustersContainer = document.getElementById('tf-clusters-container');
    const tabsContainer = document.querySelector('nav');
    const configModal = document.getElementById('config-modal');
    const configForm = document.getElementById('config-form');
    const modalTitle = document.getElementById('modal-title');
    const modalSaveBtn = document.getElementById('modal-save-btn');
    const modalCancelBtn = document.getElementById('modal-cancel-btn');

    // --- UI Update Functions ---
    function updateSocketStatus(status, color) {
        socketStatusEl.textContent = status;
        socketStatusIndicatorEl.className = `w-4 h-4 rounded-full ${color}`;
    }

    function appendToLog(message, isError = false) {
        const line = document.createElement('div');
        line.textContent = message;
        line.classList.add('log-line');
        if (isError) line.classList.add('error');
        logOutputEl.appendChild(line);
        logOutputEl.scrollTop = logOutputEl.scrollHeight;
    }

    function clearLog() { logOutputEl.innerHTML = ''; }
    
    function switchToTab(tabId) {
        document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
        document.querySelectorAll('.tab-btn').forEach(el => el.classList.remove('active'));
        document.getElementById(`tab-${tabId}`).classList.add('active');
        document.querySelector(`.tab-btn[data-tab="${tabId}"]`).classList.add('active');
    }

    function updateKubeContexts(contexts) {
        kubeContextSelect.innerHTML = '<option value="">Select an existing context...</option>';
        contexts.forEach(context => {
            const option = document.createElement('option');
            option.value = context;
            option.textContent = context;
            kubeContextSelect.appendChild(option);
        });
    }
    
    function updateCurrentContext(contextName) {
        if (contextName && contextName.startsWith("Error:")) {
            currentContextEl.textContent = contextName;
            currentContextEl.classList.add('text-red-600', 'bg-red-100');
            currentContextEl.classList.remove('text-blue-600', 'bg-blue-100');
        } else {
            currentContextEl.textContent = contextName || 'Not set';
            currentContextEl.classList.remove('text-red-600', 'bg-red-100');
            currentContextEl.classList.add('text-blue-600', 'bg-blue-100');
            kubeContextSelect.value = contextName;
        }
    }

    function updateNodesList(nodes) {
         if (nodes.error) {
            nodesListEl.innerHTML = `<tr><td colspan="5" class="text-center p-4 text-red-500">Error: ${nodes.error}</td></tr>`;
            return;
        }
        nodesListEl.innerHTML = '';
        if (!nodes || nodes.length === 0) {
            nodesListEl.innerHTML = '<tr><td colspan="5" class="text-center p-4 text-gray-500">No nodes found.</td></tr>';
            return;
        }
        nodes.forEach(node => {
            const row = document.createElement('tr');
            row.innerHTML = `
                <td class="px-6 py-4 whitespace-nowrap text-sm font-medium text-gray-900">${node.name}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm">
                    <span class="px-2 inline-flex text-xs leading-5 font-semibold rounded-full ${node.status === 'Ready' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
                        ${node.status}
                    </span>
                </td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${node.roles}</td>
                <td class="px-6 py-4 whitespace-nowrap text-sm text-gray-500">${new Date(node.age).toLocaleString()}</td>
                <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                    <button class="text-yellow-600 hover:text-yellow-900 drain-btn" data-node-name="${node.name}">Drain</button>
                    <button class="text-red-600 hover:text-red-900 delete-btn" data-node-name="${node.name}">Delete</button>
                </td>
            `;
            nodesListEl.appendChild(row);
        });
    }

    function updateTfClustersView(clusters) {
        fullTfConfig = clusters; // Store for later use in modals
        if (clusters.error) {
            tfClustersContainer.innerHTML = `<div class="bg-red-100 border-l-4 border-red-500 text-red-700 p-4" role="alert"><p class="font-bold">Error loading clusters.tf</p><p>${clusters.error}</p></div>`;
            return;
        }
        tfClustersContainer.innerHTML = '';
        for (const clusterName in clusters) {
            const cluster = clusters[clusterName];
            const clusterDiv = document.createElement('div');
            clusterDiv.className = 'bg-white p-6 rounded-xl shadow-sm border border-gray-200';
            
            let nodeClassesHtml = '<div class="mt-4 space-y-3">';
            for (const nodeClassName in cluster.node_classes) {
                const nodeClass = cluster.node_classes[nodeClassName];
                nodeClassesHtml += `
                    <div class="p-3 rounded-lg bg-gray-50 border flex justify-between items-center">
                        <h4 class="font-bold text-md text-gray-800">${nodeClassName}</h4>
                        <span class="font-semibold text-gray-700">${nodeClass.count} Nodes</span>
                    </div>
                `;
            }
            nodeClassesHtml += '</div>';

            clusterDiv.innerHTML = `
                <div class="flex justify-between items-start">
                    <div>
                        <h3 class="text-2xl font-semibold text-gray-900">${cluster.cluster_name}</h3>
                        <p class="text-sm text-gray-500">ID: ${cluster.cluster_id} | Storage: ${cluster.storage_provisioner || 'N/A'}</p>
                    </div>
                    <button class="configure-btn bg-blue-500 hover:bg-blue-600 text-white font-semibold py-2 px-4 rounded-lg transition-colors" data-cluster-name="${clusterName}">Configure</button>
                </div>
                ${nodeClassesHtml}
            `;
            tfClustersContainer.appendChild(clusterDiv);
        }
    }

    // --- Modal and Form Logic ---
    function openConfigModal(clusterName) {
        const clusterData = fullTfConfig[clusterName];
        if (!clusterData) {
            appendToLog(`Error: No config data found for cluster ${clusterName}`, true);
            return;
        }
        modalTitle.textContent = `Configure: ${clusterName}`;
        configForm.innerHTML = ''; // Clear previous form
        configForm.dataset.clusterName = clusterName;
        
        // Recursively build form fields
        buildFormFields(clusterData, configForm, []);
        
        configModal.classList.remove('hidden');
    }

    function buildFormFields(data, parentElement, path) {
        for (const key in data) {
            const value = data[key];
            const currentPath = [...path, key];
            const elementId = currentPath.join('-');

            if (key === 'node_classes') { // Special handling for node_classes
                const fieldset = document.createElement('fieldset');
                fieldset.className = 'form-group';
                fieldset.innerHTML = `<legend class="form-group-title">${key.replace(/_/g, ' ')}</legend>`;
                buildFormFields(value, fieldset, currentPath);
                parentElement.appendChild(fieldset);
                continue;
            }
            
            if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
                const fieldset = document.createElement('fieldset');
                fieldset.className = 'form-group';
                fieldset.innerHTML = `<legend class="form-group-title">${key.replace(/_/g, ' ')}</legend>`;
                buildFormFields(value, fieldset, currentPath);
                parentElement.appendChild(fieldset);
            } else if (typeof value === 'boolean') {
                const div = document.createElement('div');
                div.className = 'flex items-center justify-between py-2';
                div.innerHTML = `
                    <label for="${elementId}" class="font-medium text-gray-700">${key.replace(/_/g, ' ')}</label>
                    <input type="checkbox" id="${elementId}" name="${elementId}" ${value ? 'checked' : ''} class="h-6 w-6 rounded border-gray-300 text-blue-600 focus:ring-blue-500">
                `;
                parentElement.appendChild(div);
            } else if (typeof value === 'number') {
                 const div = document.createElement('div');
                div.innerHTML = `
                    <label for="${elementId}" class="block text-sm font-medium text-gray-700">${key.replace(/_/g, ' ')}</label>
                    <input type="number" id="${elementId}" name="${elementId}" value="${value}" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                `;
                parentElement.appendChild(div);
            } else { // String or other
                 const div = document.createElement('div');
                div.innerHTML = `
                    <label for="${elementId}" class="block text-sm font-medium text-gray-700">${key.replace(/_/g, ' ')}</label>
                    <input type="text" id="${elementId}" name="${elementId}" value="${value || ''}" class="mt-1 block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm">
                `;
                parentElement.appendChild(div);
            }
        }
    }
    
    function parseForm(formElement) {
        const formData = new FormData(formElement);
        const result = {};

        for (const [key, value] of formData.entries()) {
            const path = key.split('-');
            let current = result;
            path.forEach((p, i) => {
                if (i === path.length - 1) {
                    const el = formElement.querySelector(`[name="${key}"]`);
                    if (el.type === 'checkbox') {
                        current[p] = el.checked;
                    } else if (el.type === 'number') {
                        current[p] = parseFloat(value) || 0;
                    } else {
                        current[p] = value;
                    }
                } else {
                    if (!current[p]) {
                        // Check if the next part is a number (indicating an array index, though we don't use it here)
                        // This simplistic parser assumes object nesting only.
                        current[p] = {};
                    }
                    current = current[p];
                }
            });
        }
        return result;
    }


    function closeConfigModal() {
        configModal.classList.add('hidden');
    }

    // --- WebSocket Logic ---
    function connect() {
        socket = new WebSocket(WS_URL);

        socket.onopen = () => {
            updateSocketStatus('Connected', 'bg-green-500');
            socket.send(JSON.stringify({ type: 'get_initial_data' }));
        };

        socket.onmessage = (event) => {
            const message = JSON.parse(event.data);
            switch (message.type) {
                case 'log': appendToLog(message.data); break;
                case 'log_error': appendToLog(message.data, true); break;
                case 'command_end': appendToLog(`✅ ${message.data}`); break;
                case 'tf_clusters': updateTfClustersView(message.data); break;
                case 'kube_contexts_list': updateKubeContexts(message.data); break;
                case 'current_context': updateCurrentContext(message.data); break;
                case 'nodes_list': updateNodesList(message.data); break;
            }
        };

        socket.onclose = () => {
            updateSocketStatus('Disconnected', 'bg-red-500');
            setTimeout(connect, 5000); 
        };

        socket.onerror = (error) => {
            updateSocketStatus('Error', 'bg-red-500');
            appendToLog('WebSocket error. Check the browser console.', true);
            socket.close();
        };
    }

    function sendCommand(command, args = []) {
        if (socket.readyState !== WebSocket.OPEN) { appendToLog('WebSocket is not connected.', true); return; }
        switchToTab('logs');
        clearLog();
        socket.send(JSON.stringify({ type: 'run_command', payload: { command, args } }));
    }

    // --- Event Listeners ---
    tabsContainer.addEventListener('click', (e) => {
        if (e.target.matches('.tab-btn')) switchToTab(e.target.dataset.tab);
    });

    kubeContextSelect.addEventListener('change', (e) => { newContextInput.value = e.target.value; });

    setContextBtn.addEventListener('click', () => {
        const newContext = newContextInput.value.trim();
        if (!newContext) return;
        sendCommand('ctx', [newContext]);
        newContextInput.value = '';
    });

    bootstrapBtn.addEventListener('click', () => {
        if (confirm('Are you sure you want to bootstrap the current cluster?')) sendCommand('bootstrap');
    });
    
    refreshNodesBtn.addEventListener('click', () => {
        if (socket.readyState === WebSocket.OPEN) socket.send(JSON.stringify({ type: 'get_nodes' }));
    });

    tfClustersContainer.addEventListener('click', (e) => {
        if (e.target.matches('.configure-btn')) {
            openConfigModal(e.target.dataset.clusterName);
        }
    });

    modalSaveBtn.addEventListener('click', () => {
        const clusterName = configForm.dataset.clusterName;
        const newConfig = parseForm(configForm);
        
        if (confirm(`This will overwrite the configuration for '${clusterName}' and run 'ccr tofu apply'. Are you sure?`)) {
            socket.send(JSON.stringify({
                type: 'update_tf_cluster',
                payload: { cluster_name: clusterName, config: newConfig }
            }));
            closeConfigModal();
            switchToTab('logs');
        }
    });

    modalCancelBtn.addEventListener('click', closeConfigModal);

    nodesListEl.addEventListener('click', (e) => {
        const nodeName = e.target.dataset.nodeName;
        if (!nodeName) return;
        if (e.target.classList.contains('drain-btn')) sendCommand('drain-node', [nodeName]);
        if (e.target.classList.contains('delete-btn')) {
            if (confirm(`Are you sure you want to delete node: ${nodeName}?`)) sendCommand('delete-node', [nodeName]);
        }
    });

    clearLogBtn.addEventListener('click', clearLog);

    // --- Initial Load ---
    switchToTab('dashboard');
    connect();
});
