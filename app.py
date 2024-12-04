from flask import Flask, request, render_template
import pickle
import numpy as np

app = Flask(__name__)

# Load the trained model
model = pickle.load(open('model.pkl', 'rb'))

@app.route('/')
def home():
    # Render the form for input
    return render_template('index.html')

@app.route('/predict', methods=['POST'])
def predict():
    # Get input data from the form
    features = [
        int(request.form['feature1']),
        int(request.form['feature2']),
        int(request.form['feature3']),
        int(request.form['feature4']),
        int(request.form['feature5']),
        int(request.form['feature6']),
        int(request.form['feature7']),
        int(request.form['feature8']),
        int(request.form['feature9']),
        int(request.form['feature10']),
        int(request.form['feature11']),
        int(request.form['feature12'])
    ]

    # Convert the input data into a numpy array and reshape it for prediction
    features = np.array(features).reshape(1, -1)
    prediction = model.predict(features)[0]

    # Return the prediction
    if prediction == 1:
        result = "There are signs that your child may be showing early signs of Autism."
    else:
        result = "It seems like your child is not showing signs of Autism."
    
    return render_template('index.html', prediction_text=result)

if __name__ == '__main__':
    app.run(debug=True, port=8080)