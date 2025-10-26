from flask import Flask, jsonify, render_template, request
import os

app = Flask(__name__, static_folder='static', template_folder='templates')


@app.route('/')
def index():
    """Render the web UI for the application.

    The template receives a small `info` object that includes a message and
    an application version (populated from the APP_VERSION env var).
    """
    info = {
        'message': 'Hello from Flask on Kubernetes!',
        'version': os.environ.get('APP_VERSION', 'v0.1')
    }
    return render_template('index.html', info=info)


@app.route('/api/info')
def api_info():
    """Simple JSON endpoint returning application info for the frontend."""
    return jsonify({
        'message': 'Hello from Flask API',
        'version': os.environ.get('APP_VERSION', 'v0.1')
    })


@app.route('/api/greet', methods=['POST'])
def api_greet():
    """Endpoint to accept a name and return a personalized greeting.

    The frontend posts JSON: { "name": "Alice" } and receives a greeting.
    """
    data = request.get_json(silent=True) or {}
    name = data.get('name') or 'visitor'
    return jsonify({
        'greeting': f'Hello, {name}! Welcome to the Flask app.'
    })


@app.route('/healthz')
def health():
    return 'OK', 200


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 8080)))
