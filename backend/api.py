from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import joblib
from pathlib import Path


# =========================================================
# 1. APP
# =========================================================

app = FastAPI(
    title="SMS Spam Detection API",
    description="Machine Learning based SMS Spam Detection API",
    version="1.0.0"
)

# Enable CORS for mobile & web clients
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)



# =========================================================
# 2. FILE PATHS
# =========================================================

# Current folder:
# backend/

BASE_DIR = Path(__file__).resolve().parent

# Go one folder up → project root
PROJECT_DIR = BASE_DIR.parent

# ML folder
ML_DIR = PROJECT_DIR / "ml"

VECTORIZER_PATH = ML_DIR / "vectorizer.pkl"
MODEL_PATH = ML_DIR / "spam_model.pkl"


# =========================================================
# 3. LOAD TRAINED MODEL
# =========================================================

vectorizer = joblib.load(
    VECTORIZER_PATH
)

model = joblib.load(
    MODEL_PATH
)


# =========================================================
# 4. REQUEST FORMAT
# =========================================================

class SMSRequest(BaseModel):

    message: str


# =========================================================
# 5. PREDICTION API
# =========================================================

@app.post("/predict")
def predict_sms(request: SMSRequest):

    message = request.message

    # -----------------------------------------------------
    # CONVERT SMS INTO NUMERICAL FEATURES
    # -----------------------------------------------------

    message_vector = vectorizer.transform(
        [message]
    )

    # -----------------------------------------------------
    # PREDICTION
    # -----------------------------------------------------

    prediction = model.predict(
        message_vector
    )[0]

    # -----------------------------------------------------
    # PROBABILITY
    # -----------------------------------------------------

    probabilities = model.predict_proba(
        message_vector
    )[0]

    ham_probability = float(
        probabilities[0]
    )

    spam_probability = float(
        probabilities[1]
    )

    # -----------------------------------------------------
    # CONVERT NUMERICAL PREDICTION TO TEXT
    # -----------------------------------------------------

    if prediction == 1:

        result = "spam"

    else:

        result = "ham"

    # -----------------------------------------------------
    # API RESPONSE
    # -----------------------------------------------------

    return {

        "prediction": result,

        "spam_probability": spam_probability,

        "ham_probability": ham_probability

    }