from flask import Blueprint, render_template, request
import requests
from forecast import Forecast


views = Blueprint(__name__, "views")                                                   
key = '5bb5a99a036951f1cd3dd0529052f0e9'                                                         
                                                                                                
@views.route("/")
def home():
    return render_template("index.html")                    


@views.route("/", methods=['GET', 'POST'])                                                   
def get_api():                                                                      
    location = request.form['location']
    response = requests.get(f"https://api.openweathermap.org/data/2.5/forecast?q={location}&appid={key}")
    data = response.json()                                                                       
    if response.status_code == 200:
        fore_list = []                                                                           
        fore_list.append(data['city']['name'])                                                   
        fore_list.append(data['city']['country'])                                                 
        for element in data['list']:                                                              
            if element['dt_txt'][11:] == '09:00:00' or element['dt_txt'][11:] == '21:00:00':     
                date = element['dt_txt'][:10]
                time = element['dt_txt'][11:19]
                temp = element["main"]["temp"] 
                humidity = element["main"]["humidity"]                                          
                obj = Forecast(date, time, temp, humidity)                                   
                fore_list.append(obj)                                                    
        return render_template("index.html", data_list=fore_list)                               
    else:
        return "Error: bad input (probally there is no such country or city)"

    

