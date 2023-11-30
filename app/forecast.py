class Forecast:
    def __init__(self, date, time, temp, humidity):
        self.date = date
        self.time = time
        self.temp = round(temp - 273.15, 2)
        self.humidity = humidity
        self.is_forecast = True             #to alte apply specific css to each item in the list 