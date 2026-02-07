import jyotichart
import os

try:
    my_chart = jyotichart.NorthChart("Kushal_Birth Chart", "Kushal", IsFullChart=False)
    
    my_chart.set_ascendantsign("Aries")
    my_chart.add_planet("Sun", "Su", 1)
    my_chart.add_planet("Moon", "Mo", 5)
    
    my_chart.draw(".", "Kushal_Birth Chart")
    
    if os.path.exists("Kushal_Birth Chart.svg"):
        print("SUCCESS: File created")
        os.remove("Kushal_Birth Chart.svg")
    else:
        print("ERROR: File not created")
except Exception as e:
    print(f"EXCEPTION: {e}")
