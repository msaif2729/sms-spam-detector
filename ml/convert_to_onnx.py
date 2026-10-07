import joblib
import numpy as np
from pathlib import Path
from sklearn.pipeline import Pipeline
from skl2onnx import to_onnx
from skl2onnx.common.data_types import StringTensorType, FloatTensorType
import onnxruntime as rt

BASE_DIR = Path(__file__).resolve().parent
VECTORIZER_PATH = BASE_DIR / "vectorizer.pkl"
MODEL_PATH = BASE_DIR / "spam_model.pkl"
ONNX_PIPELINE_PATH = BASE_DIR / "sms_spam_pipeline.onnx"
ONNX_MODEL_PATH = BASE_DIR / "spam_model.onnx"

def main():
    print("Loading vectorizer and model...")
    vectorizer = joblib.load(VECTORIZER_PATH)
    model = joblib.load(MODEL_PATH)

    # 1. Convert combined Pipeline (Text String -> Prediction)
    print("Building sklearn Pipeline...")
    pipeline = Pipeline([
        ('vectorizer', vectorizer),
        ('classifier', model)
    ])

    print("Converting Pipeline to ONNX format (StringTensorType)...")
    initial_type_str = [('input_text', StringTensorType([None, 1]))]
    onx_pipeline = to_onnx(
        pipeline,
        initial_types=initial_type_str,
        target_opset=15
    )

    with open(ONNX_PIPELINE_PATH, "wb") as f:
        f.write(onx_pipeline.SerializeToString())
    print(f"[SUCCESS] Saved Pipeline ONNX model: {ONNX_PIPELINE_PATH}")

    # 2. Convert Classifier Model standalone (Feature Vector -> Prediction)
    print("Converting MultinomialNB model standalone to ONNX format...")
    n_features = len(vectorizer.get_feature_names_out())
    initial_type_vec = [('float_input', FloatTensorType([None, n_features]))]
    onx_model = to_onnx(
        model,
        initial_types=initial_type_vec,
        target_opset=15
    )

    with open(ONNX_MODEL_PATH, "wb") as f:
        f.write(onx_model.SerializeToString())
    print(f"[SUCCESS] Saved Classifier ONNX model: {ONNX_MODEL_PATH}")

    # 3. Verify ONNX Inference using ONNX Runtime
    print("\n--- Testing ONNX Inference ---")
    test_msg = "Congratulations! You won a free gift card. Click here to claim."
    
    # Test Pipeline ONNX model
    sess = rt.InferenceSession(str(ONNX_PIPELINE_PATH))
    input_name = sess.get_inputs()[0].name
    
    inputs = {input_name: np.array([[test_msg]], dtype=object)}
    res = sess.run(None, inputs)
    
    label_pred = res[0][0]
    probabilities = res[1][0]
    
    print(f"Input Message: '{test_msg}'")
    print(f"ONNX Predicted Label: {'spam' if label_pred == 1 else 'ham'} (raw class: {label_pred})")
    print(f"ONNX Probabilities (Ham vs Spam): {probabilities}")
    print("\nConversion & Verification completed successfully!")

if __name__ == "__main__":
    main()
