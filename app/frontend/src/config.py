"""
Configuration for Flask API connection
"""

# API Configuration
API_HOST = "127.0.0.1"  # или "localhost"
API_PORT = 5000

# API Endpoints
API_BASE_URL = f"http://{API_HOST}:{API_PORT}"
GET_USERS_URL = f"{API_BASE_URL}/getusers"
SET_USERS_URL = f"{API_BASE_URL}/setusers"

# Request timeout (seconds)
REQUEST_TIMEOUT = 10

# Default values
DEFAULT_NUM_ROWS = 10