from flask import Flask, request, render_template
import pickle
import numpy as np
from tensorflow.keras.models import load_model
from PIL import Image
import io

app = Flask(__name__)

# Load the trained .pkl model
try:
    model = pickle.load(open('model.pkl', 'rb'))
except Exception as e:
    print(f"Error loading model: {e}")
    model = None

# Load the .h5 model (for image prediction)
try:
    image_model = load_model('facial_recognition.h5')
except Exception as e:
    print(f"Error loading image model: {e}")
    image_model = None

# Model accuracy weights
accuracy_pkl = 0.9896
accuracy_h5 = 0.8167

def prepare_image(image):
    """Preprocess the uploaded image for prediction."""
    img = Image.open(image).convert('RGB')  # Ensure image is RGB
    img = img.resize((224, 224))  # Resize to the expected input shape (224x224)
    img = np.array(img) / 255.0  # Normalize to [0, 1] range
    img = np.expand_dims(img, axis=0)  # Add batch dimension
    return img

@app.route('/')
def home():
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict():
    try:
        image_prediction = None
        tabular_prediction = None
        
        if 'image' in request.files and request.files['image'].filename != '':
            file = request.files['image']
            img = prepare_image(file)
            
            if image_model is None:
                return render_template('index.html', prediction_text="Image model not loaded properly!")
            
            raw_image_prediction = image_model.predict(img)[0][0]  # Probability of 'non_autistic' class in .h5 model
            image_prediction = 1 - raw_image_prediction  # Convert to match .pkl format
        
        features = []
        for i in range(1, 13):
            value = request.form.get(f'feature{i}', "").strip()
            try:
                features.append(float(value))
            except ValueError:
                return render_template('index.html', prediction_text=f"Invalid input in feature {i}. Please enter valid numbers.")
        
        features = np.array(features).reshape(1, -1)
        
        if model is None:
            return render_template('index.html', prediction_text="Model not loaded properly!")
        
        probabilities = model.predict_proba(features)[0]  # Get probabilities
        tabular_prediction = probabilities[1]  # Probability of 'autistic' class
        
        if image_prediction is not None:
            # Weighted combination of both models
            final_score = (accuracy_pkl * tabular_prediction + accuracy_h5 * image_prediction) / (accuracy_pkl + accuracy_h5)
        else:
            final_score = tabular_prediction  # If no image, use only tabular prediction
        
        confidence_percentage = final_score * 100
        diagnosis = "Autistic" if final_score >= 0.5 else "Non-Autistic"
        result = f"There is a {confidence_percentage:.2f}% likelihood that the infant exhibits ASD traits. Therefore, the infant is likely {diagnosis}."
        
        return render_template('index.html', prediction_text=result)
    
    except Exception as e:
        return render_template('index.html', prediction_text=f"Error: {str(e)}")

if __name__ == '__main__':
    app.run(debug=True, port=8080)
