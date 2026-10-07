import onnxruntime as rt
import numpy as np
from pathlib import Path

# Resolve path relative to script location
BASE_DIR = Path(__file__).resolve().parent
ONNX_PATH = BASE_DIR / "sms_spam_pipeline.onnx"

def predict_sms(message: str, session: rt.InferenceSession):
    input_name = session.get_inputs()[0].name
    
    # Format input as a 2D string numpy array [1, 1]
    input_data = {input_name: np.array([[message]], dtype=object)}
    result = session.run(None, input_data)
    
    # Extract prediction label & probability dictionary
    raw_label = result[0][0]  # 1 = Spam, 0 = Ham
    probs = result[1][0]      # Map {0: ham_prob, 1: spam_prob}
    
    label_text = "SPAM" if raw_label == 1 else "HAM (Legitimate)"
    ham_prob = probs.get(0, 0.0) * 100
    spam_prob = probs.get(1, 0.0) * 100
    
    return {
        "message": message,
        "label": label_text,
        "is_spam": raw_label == 1,
        "spam_probability": spam_prob,
        "ham_probability": ham_prob
    }

def main():
    print(f"Loading ONNX Model from: {ONNX_PATH}")
    session = rt.InferenceSession(str(ONNX_PATH))
    
    sample_messages = [
        "Win a free cash prize of $1000 now! Click http://win-now.com to claim.",
        "Hey, are we still meeting for dinner tonight at 7 PM?",
        "URGENT: Your bank account access is suspended. Verify credentials immediately.",
        "Your package shipment #94827 has been delivered."
    ]
    
    print("\n" + "=" * 65)
    print("           SMS SPAM DETECTOR - ONNX MODEL INFERENCE           ")
    print("=" * 65 + "\n")
    
    for idx, msg in enumerate(sample_messages, 1):
        res = predict_sms(msg, session)
        print(f"Sample #{idx}: \"{res['message']}\"")
        print(f"  Classification : {res['label']}")
        print(f"  Spam Confidence: {res['spam_probability']:.2f}%")
        print(f"  Ham Confidence : {res['ham_probability']:.2f}%")
        print("-" * 65)

if __name__ == "__main__":
    main()
