#!/usr/bin/env python3
"""
Web-based Frontend for User Management API
Flask server serving HTML/JS interface
"""

import os
from flask import Flask, render_template, request, jsonify
import requests
import logging

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configuration from environment variables
API_HOST = os.getenv('BACKEND_API_HOST')
API_PORT = os.getenv('BACKEND_API_PORT')
API_BASE_URL = f"http://{API_HOST}:{API_PORT}"

logger.info(f"Backend API URL: {API_BASE_URL}")


@app.route('/')
def index():
    """Serve main page"""
    return render_template('index.html', api_url=API_BASE_URL)


@app.route('/health')
def health():
    """Frontend health check"""
    return jsonify({
        'status': 'healthy',
        'service': 'frontend',
        'backend_api': API_BASE_URL
    }), 200


@app.route('/api/check_backend')
def check_backend():
    """Check if backend API is accessible"""
    try:
        response = requests.get(
            f"{API_BASE_URL}/healthcheck",
            timeout=5
        )
        return jsonify({
            'status': 'connected',
            'backend_response': response.json()
        }), 200
    except requests.exceptions.RequestException as e:
        logger.error(f"Backend connection failed: {e}")
        return jsonify({
            'status': 'error',
            'message': str(e)
        }), 503


@app.route('/api/users', methods=['GET'])
def get_users():
    """Proxy GET users request to backend"""
    try:
        num_row = request.args.get('num_row', '10')
        
        logger.info(f"Fetching {num_row} users from backend")
        
        response = requests.get(
            f"{API_BASE_URL}/getusers",
            params={'num_row': num_row},
            timeout=10
        )
        
        return jsonify(response.json()), response.status_code
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Error fetching users: {e}")
        return jsonify({
            'error': 'Backend API unavailable',
            'details': str(e)
        }), 503


@app.route('/api/users', methods=['POST'])
def create_user():
    """Proxy POST create user request to backend"""
    try:
        user_data = request.json
        
        logger.info(f"Creating user: {user_data.get('username')}")
        
        response = requests.post(
            f"{API_BASE_URL}/setusers",
            json=user_data,
            headers={'Content-Type': 'application/json'},
            timeout=10
        )
        
        return jsonify(response.json()), response.status_code
        
    except requests.exceptions.RequestException as e:
        logger.error(f"Error creating user: {e}")
        return jsonify({
            'error': 'Backend API unavailable',
            'details': str(e)
        }), 503


if __name__ == '__main__':
    port = int(os.getenv('FRONTEND_PORT', 7000))
    logger.info(f"Starting frontend server on port {port}")
    app.run(
        host='0.0.0.0',
        port=port,
        debug=os.getenv('FLASK_ENV') == 'development'
    )