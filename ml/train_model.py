import pandas as pd
import joblib
from pathlib import Path
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report
from skl2onnx import to_onnx
from skl2onnx.common.data_types import StringTensorType

BASE_DIR = Path(__file__).resolve().parent
DATASET_PATH = BASE_DIR / "SMSSpamCollection"
VECTORIZER_PATH = BASE_DIR / "vectorizer.pkl"
MODEL_PATH = BASE_DIR / "spam_model.pkl"
ONNX_PIPELINE_PATH = BASE_DIR / "sms_spam_pipeline.onnx"

def train():
    print("Loading dataset from SMSSpamCollection...")
    df = pd.read_csv(
        DATASET_PATH,
        sep="\t",
        header=None,
        names=["label", "message"],
        encoding="utf-8"
    )

    # Encode label: ham -> 0, spam -> 1
    df["label"] = df["label"].map({"ham": 0, "spam": 1})
    df = df.dropna()

    X = df["message"]
    y = df["label"]

    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )

    print("Fitting CountVectorizer & MultinomialNB model...")
    vectorizer = CountVectorizer()
    X_train_vec = vectorizer.fit_transform(X_train)

    model = MultinomialNB()
    model.fit(X_train_vec, y_train)

    # Evaluate
    X_test_vec = vectorizer.transform(X_test)
    y_pred = model.predict(X_test_vec)
    acc = accuracy_score(y_test, y_pred)
    print(f"Test Set Accuracy: {acc * 100:.2f}%\n")
    print(classification_report(y_test, y_pred, target_names=["Ham", "Spam"]))

    # Save Pickle (.pkl) files
    joblib.dump(vectorizer, VECTORIZER_PATH)
    joblib.dump(model, MODEL_PATH)
    print(f"[SUCCESS] Saved vectorizer.pkl and spam_model.pkl to {BASE_DIR}")

    # Convert to ONNX (.onnx)
    pipeline = Pipeline([
        ('vectorizer', vectorizer),
        ('classifier', model)
    ])
    initial_type = [('input_text', StringTensorType([None, 1]))]
    onx = to_onnx(pipeline, initial_types=initial_type, target_opset=15)
    
    with open(ONNX_PIPELINE_PATH, "wb") as f:
        f.write(onx.SerializeToString())
    print(f"[SUCCESS] Saved ONNX model: {ONNX_PIPELINE_PATH}")

if __name__ == "__main__":
    train()
