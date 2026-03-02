import cv2
import urllib.request
import numpy as np

def analyze_face(url):
    try:
        resp = urllib.request.urlopen(url)
        image = np.asarray(bytearray(resp.read()), dtype="uint8")
        image = cv2.imdecode(image, cv2.IMREAD_COLOR)

        gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
        face_cascade = cv2.CascadeClassifier(cv2.data.haarcascades + 'haarcascade_frontalface_default.xml')
        
        faces = face_cascade.detectMultiScale(gray, 1.3, 5)
        print("Faces found:", len(faces))
        for (x,y,w,h) in faces:
            print(f"Face bounds: x={x} y={y} w={w} h={h}")
    except Exception as e:
        print("Error:", e)
        
analyze_face("https://upload.wikimedia.org/wikipedia/commons/a/a2/Tushar_Gandhi_2013-10-02_20-41.jpg")
