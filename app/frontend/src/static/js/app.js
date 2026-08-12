// Global state
let backendConnected = false;

// Check backend connection on page load
document.addEventListener('DOMContentLoaded', () => {
    checkBackendConnection();
    setupEventListeners();
});

function setupEventListeners() {
    // Get All checkbox toggle
    const getAllCheckbox = document.getElementById('get_all_checkbox');
    const numRowInput = document.getElementById('num_row');
    
    getAllCheckbox.addEventListener('change', (e) => {
        if (e.target.checked) {
            numRowInput.value = 'ALL';
            numRowInput.disabled = true;
        } else {
            numRowInput.value = '10';
            numRowInput.disabled = false;
        }
    });
}

async function checkBackendConnection() {
    const statusText = document.getElementById('api-status-text');
    const statusIndicator = document.getElementById('api-status-indicator');
    
    try {
        const response = await fetch('/api/check_backend');
        const data = await response.json();
        
        if (data.status === 'connected') {
            statusText.textContent = '✅ Backend Connected';
            statusIndicator.className = 'status-indicator connected';
            backendConnected = true;
            appendResult('=== Backend API Connected ===');
            appendResult(JSON.stringify(data.backend_response, null, 2));
        } else {
            throw new Error('Backend not connected');
        }
    } catch (error) {
        statusText.textContent = '❌ Backend Unavailable';
        statusIndicator.className = 'status-indicator error';
        backendConnected = false;
        appendResult('❌ Cannot connect to backend API');
        appendResult(`Error: ${error.message}`);
    }
}

async function getUsers() {
    const numRow = document.getElementById('num_row').value.trim();
    
    if (!numRow) {
        alert('Please enter number of users');
        return;
    }
    
    if (numRow !== 'ALL' && (!Number.isInteger(Number(numRow)) || Number(numRow) < 1)) {
        alert('Please enter a positive integer or "ALL"');
        return;
    }
    
    appendResult(`\n=== GET USERS Request (num_row=${numRow}) ===`);
    
    try {
        const response = await fetch(`/api/users?num_row=${numRow}`);
        const data = await response.json();
        
        if (response.ok) {
            if (data.ok) {
                appendResult(`✅ Retrieved ${data.ok.length} users:`);
                appendResult(JSON.stringify(data.ok, null, 2));
            } else {
                appendResult(JSON.stringify(data, null, 2));
            }
        } else {
            appendResult(`❌ Error ${response.status}:`);
            appendResult(JSON.stringify(data, null, 2));
        }
    } catch (error) {
        appendResult(`❌ Request failed: ${error.message}`);
    }
}

async function createUser(event) {
    event.preventDefault();
    
    const userData = {
        username: document.getElementById('username').value.trim(),
        password: document.getElementById('password').value.trim(),
        email: document.getElementById('email').value.trim(),
        remarks: document.getElementById('remarks').value.trim() || null
    };
    
    if (!userData.username || !userData.password || !userData.email) {
        alert('Please fill in all required fields');
        return;
    }
    
    appendResult(`\n=== CREATE USER Request ===`);
    appendResult(`Data: ${JSON.stringify(userData, null, 2)}`);
    
    try {
        const response = await fetch('/api/users', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(userData)
        });
        
        const data = await response.json();
        
        if (response.ok) {
            appendResult(`✅ Success:`);
            appendResult(JSON.stringify(data, null, 2));
            clearForm();
            alert(`User '${userData.username}' created successfully!`);
        } else {
            appendResult(`❌ Error ${response.status}:`);
            appendResult(JSON.stringify(data, null, 2));
            alert(`Error: ${data.error || 'Unknown error'}`);
        }
    } catch (error) {
        appendResult(`❌ Request failed: ${error.message}`);
        alert(`Request failed: ${error.message}`);
    }
}

function clearForm() {
    document.getElementById('create-user-form').reset();
}

function appendResult(text) {
    const resultsBox = document.getElementById('results');
    
    // Remove empty message if exists
    const emptyMsg = resultsBox.querySelector('.results-empty');
    if (emptyMsg) {
        emptyMsg.remove();
    }
    
    resultsBox.textContent += text + '\n';
    resultsBox.scrollTop = resultsBox.scrollHeight;
}

function clearResults() {
    const resultsBox = document.getElementById('results');
    resultsBox.innerHTML = '<div class="results-empty">No results yet. Perform an action above.</div>';
}