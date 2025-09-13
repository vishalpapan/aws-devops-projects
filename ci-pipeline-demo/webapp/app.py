from flask import Flask

app = Flask(__name__)

@app.route('/')
def home():
    return '<h1>Hello from CI/CD Demo App!</h1><p>This Flask app is ready for AWS CI/CD pipeline.</p>'

@app.route('/health')
def health():
    return {'status': 'healthy', 'message': 'Application is running'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)