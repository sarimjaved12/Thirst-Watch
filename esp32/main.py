import network
import urequests

from machine import Pin
from hx711 import HX711
from time import sleep

from config import SSID, PASSWORD

FIREBASE_URL = "https://thirst-watch-default-rtdb.firebaseio.com/water-intake.json"

# Connect to WiFi
def connect_wifi():
    wlan = network.WLAN(network.STA_IF)
    wlan.active(True)
    wlan.connect(SSID, PASSWORD)
    while not wlan.isconnected():
        print("Connecting to WiFi...")
        sleep(1)
    print("Connected:", wlan.ifconfig())

hx = HX711(Pin(21), Pin(22))
hx.set_reference_unit(1720)  

print("Taring... make sure only the platform is on the sensor.")
hx.tare()
print("Tare complete.")

sleep(2)
print("Place full bottle on the platform...")
sleep(5)

# Capture the full bottle weight
initial_weight = hx.get_weight(10)
print("Initial weight:", initial_weight, "ml")

last_valid_weight = initial_weight
bottle_present = True
drop_threshold = initial_weight * 0.4  # assume bottle lifted if weight drops below this
grace_period = 10  # Grace period in seconds to handle temporary drops
grace_timer = 0

connect_wifi()

while True:
    weight = hx.get_weight(5)

    # Detect bottle lift (weight drops significantly)
    if weight < drop_threshold:
        if bottle_present:
            print("Weight dropped below threshold. Starting grace period...")
            grace_timer += 1
            if grace_timer >= grace_period:
                print("Bottle removed. Holding last known good value.")
                bottle_present = False
                weight = last_valid_weight
        else:
            weight = last_valid_weight
    else:
        # Reset grace timer and update last valid weight
        grace_timer = 0
        last_valid_weight = weight
        bottle_present = True

    # Calculate water left and water drank
    water_left = max(0, last_valid_weight)
    water_drank = max(0, initial_weight - water_left)

    print(f"Water left: {water_left:.1f} ml")
    print(f"Water drank: {water_drank:.1f} ml")
    print("------")
    
    # Send data to Firebase
    data = {
        "water_left": water_left,
        "water_drank": water_drank
    }

    try:
        res = urequests.put(FIREBASE_URL, json=data)
        print("Sent to Firebase:", res.text)
        res.close()
    except Exception as e:
        print("Firebase error:", e)

    sleep(5)

    

