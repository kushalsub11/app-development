import jyotichart as chart
import os

try:
    my_chart = chart.NorthChart("TestChart", "Test User", IsFullChart=False)
    
    # Sun in 1st house (Aries sign="Aries")
    my_chart.set_ascendantsign("Aries")
    my_chart.add_planet(planet="SUN", symbol="Su", housenum=1)
    
    # Draw saves to {location}/{filename}.svg
    my_chart.draw(".", "TestChart") 
    
    if os.path.exists("TestChart.svg"):
        print("SUCCESS: File created")
        os.remove("TestChart.svg")
    else:
        print("ERROR: File not found")
except Exception as e:
    print(f"EXCEPTION: {e}")
