# SMS Spam Detector

A Machine Learning based SMS Spam Detection system that classifies SMS messages as **Spam** or **Ham (Legitimate)** using **Natural Language Processing (NLP)** and the **Multinomial Naive Bayes** algorithm.

The project provides both a **Streamlit web interface** for testing SMS messages and a **FastAPI REST API** for integrating the trained model with a mobile application.

\---

## Features

* SMS spam and ham classification
* NLP-based text vectorization using `CountVectorizer`
* Multinomial Naive Bayes classification
* Accuracy, Precision, Recall and F1 Score
* Confusion Matrix
* Spam and ham probability
* Suspicious keyword detection
* Streamlit-based web dashboard
* FastAPI REST API
* Ready for Android/mobile application integration

\---

## Project Structure

```text
SMS-Spam-Detector/
│
├── ml/
│   ├── SMSSpamCollection
│   ├── train_model.py          # Trains model & exports .pkl + .onnx
│   ├── convert_to_onnx.py      # Converts .pkl models to ONNX
│   ├── spam_model.pkl          # Saved Multinomial Naive Bayes model
│   ├── vectorizer.pkl          # Saved CountVectorizer
│   ├── sms_spam_pipeline.onnx  # End-to-End ONNX Pipeline
│   └── spam_model.onnx         # Standalone ONNX Classifier
│
├── backend/
│   ├── api.py                  # FastAPI REST API with CORS
│   └── requirements.txt        # Backend dependencies
│
├── streamlit/
│   └── app.py                  # Interactive Web Dashboard
│
└── mobile_app/                 # Flutter Cross-Platform Mobile Application
```

### Folder Description

|Folder/File|Purpose|
|-|-|
|`ml/`|Machine Learning model, dataset, and ONNX conversion scripts|
|`SMSSpamCollection`|SMS dataset|
|`train_model.py`|Trains model and saves `.pkl` and `.onnx` artifacts|
|`convert_to_onnx.py`|Converts scikit-learn `.pkl` models to `.onnx` format|
|`sms_spam_pipeline.onnx`|End-to-end string-to-prediction ONNX model|
|`spam_model.onnx`|Standalone classifier ONNX model|
|`backend/`|FastAPI backend service|
|`api.py`|REST API for SMS prediction|
|`streamlit/`|Streamlit dashboard|
|`app.py`|Web analytics interface|
|`mobile_app/`|Flutter Mobile Application for Android / Web / Desktop|


\---

# Requirements

## Python

Python 3.10 or later is recommended.

Check your Python version:

```bash
python --version
```

Check pip:

```bash
pip --version
```

\---

# Installation

## 1\. Clone the Repository

```bash
git clone <YOUR-GITHUB-REPOSITORY-URL>
```

Go to the project directory:

```bash
cd SMS-Spam-Detector
```

\---

## 2\. Create a Virtual Environment

### Windows

```bash
python -m venv venv
```

Activate the virtual environment.

### Command Prompt

```bash
venv\\Scripts\\activate
```

### PowerShell

```powershell
venv\\Scripts\\Activate.ps1
```

After activation, the terminal should show:

```text
(venv)
```

\---

## 3\. Install Python Packages

Install the required packages:

```bash
pip install -r backend/requirements.txt
```

The project uses:

```text
pandas
numpy
scikit-learn
joblib
streamlit
fastapi
uvicorn
pydantic
```

\---

# Machine Learning Model

## 4\. Dataset

Place the `SMSSpamCollection` dataset inside the `ml` folder:

```text
ml/
├── SMSSpamCollection
└── train\_model.py
```

The dataset contains SMS messages labelled as:

```text
ham
spam
```

\---

## 5\. Train the Model

From the project root directory, run:

```bash
python ml/train\_model.py
```

After successful training, the following files should be available:

```text
ml/
├── SMSSpamCollection
├── train\_model.py
├── spam\_model.pkl
└── vectorizer.pkl
```

### Generated Files

**`spam\_model.pkl`**

Contains the trained Multinomial Naive Bayes classification model.

**`vectorizer.pkl`**

Contains the trained `CountVectorizer` used to convert SMS text into numerical features.

These files are loaded by both the Streamlit application and FastAPI backend.

\---

# Streamlit Application

## 6\. Run Streamlit

From the project root:

```bash
streamlit run streamlit/app.py
```

The application will normally be available at:

```text
http://localhost:8501
```

The Streamlit dashboard provides:

* Dataset information
* Number of ham and spam messages
* Model performance
* Confusion matrix
* SMS message input
* Spam/ham prediction
* Spam probability
* Ham probability
* Suspicious keyword detection
* Sample dataset

\---

# FastAPI Backend

## 7\. Run FastAPI

From the project root:

```bash
uvicorn backend.api:app --reload
```

The API will normally run at:

```text
http://127.0.0.1:8000
```

\---

## 8\. Open API Documentation

FastAPI automatically provides interactive API documentation.

Open:

```text
http://127.0.0.1:8000/docs
```

\---

# Prediction API

## Endpoint

```text
POST /predict
```

### Request

Send an SMS message in JSON format:

```json
{
    "message": "Congratulations! You have won a free prize. Click here to claim."
}
```

### Response

Example:

```json
{
    "prediction": "spam",
    "spam\_probability": 0.98,
    "ham\_probability": 0.02
}
```

### Response Fields

|Field|Description|
|-|-|
|`prediction`|Predicted class: `spam` or `ham`|
|`spam\_probability`|Probability assigned to spam|
|`ham\_probability`|Probability assigned to ham|

\---

# Running the Complete System

The Streamlit dashboard and FastAPI backend can be run simultaneously using two terminals.

## Terminal 1 — FastAPI

From the project root:

```bash
venv\\Scripts\\activate
uvicorn backend.api:app --reload
```

## Terminal 2 — Streamlit

From the project root:

```bash
venv\\Scripts\\activate
streamlit run streamlit/app.py
```

The services will be available at:

```text
Streamlit:
http://localhost:8501

FastAPI:
http://127.0.0.1:8000

FastAPI Documentation:
http://127.0.0.1:8000/docs
```

\---

# Mobile Application Integration

The FastAPI backend acts as the connection between the mobile application and the Machine Learning model.

```text
┌─────────────────────┐
│   Android App       │
│                     │
│ Enter SMS Message   │
└──────────┬──────────┘
           │
           │ POST /predict
           ▼
┌─────────────────────┐
│   FastAPI Backend   │
│                     │
│ Receive SMS         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   CountVectorizer   │
│                     │
│ Text → Features     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Multinomial Naive   │
│ Bayes Model         │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Prediction          │
│                     │
│ Spam / Ham          │
└──────────┬──────────┘
           │
           │ JSON Response
           ▼
┌─────────────────────┐
│   Android App       │
│                     │
│ Display Result      │
└─────────────────────┘
```

The mobile application sends:

```json
{
    "message": "You have won a free prize!"
}
```

The FastAPI backend processes the message using the saved ML model and returns the classification and probabilities.

\---

# Important File Paths

The Streamlit application uses:

```python
DATASET\_PATH = "../ml/SMSSpamCollection"

VECTORIZER\_PATH = "../ml/vectorizer.pkl"

MODEL\_PATH = "../ml/spam\_model.pkl"
```

The FastAPI backend uses the `ml` folder relative to its own location:

```text
backend/api.py
       ↓
project root
       ↓
ml/
├── spam\_model.pkl
└── vectorizer.pkl
```

This allows the applications to find the model files regardless of the current working directory.

\---

# Important Commands

|Task|Command|
|-|-|
|Create virtual environment|`python -m venv venv`|
|Activate environment|`venv\\Scripts\\activate`|
|Install dependencies|`pip install -r backend/requirements.txt`|
|Train ML model|`python ml/train\_model.py`|
|Run Streamlit|`streamlit run streamlit/app.py`|
|Run FastAPI|`uvicorn backend.api:app --reload`|
|Check Python version|`python --version`|

\---

# Deactivate Virtual Environment

When you finish working on the project:

```bash
deactivate
```

\---

# Notes

* The `SMSSpamCollection` dataset must be present in the `ml` folder before training.
* Run `train\_model.py` before starting the applications if the `.pkl` files do not exist.
* Do not delete `spam\_model.pkl` or `vectorizer.pkl` unless you plan to retrain the model.
* The Streamlit application is used for the web-based ML demonstration.
* The FastAPI application provides the REST API for mobile integration.
* The Android application communicates with the FastAPI backend rather than directly loading the Python ML model.
* Do not store passwords, API keys, tokens, or other sensitive information in the repository.

