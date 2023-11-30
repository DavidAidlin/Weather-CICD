from flask import Flask
from views import views

app = Flask(__name__)
app.register_blueprint(views, url_prefix="/")



if __name__ == '__main__':
    app.run()


'''
app is an instance of the Flask class, which represents the Flask application
app.run(host='0.0.0.0')
the register_blueprint() method is used to associate a blueprint with the application
'''
