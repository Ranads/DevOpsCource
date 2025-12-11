from flask import Flask

app = Flask(__name__)

@app.route("/")
def hello():
    return "Hello Ranad! 🚀 taet the CI/CD pipline "

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=80)