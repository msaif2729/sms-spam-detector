import streamlit as st
import pandas as pd
import joblib
import altair as alt

from sklearn.metrics import (
    accuracy_score,
    precision_score,
    recall_score,
    f1_score,
    confusion_matrix
)


# =========================================================
# 1. PAGE CONFIGURATION
# =========================================================

st.set_page_config(
    page_title="SMS Spam Detector",
    page_icon="📱",
    layout="centered"
)

# =========================================================
# 1.1 GLOBAL UI STYLING & ANIMATIONS
# =========================================================

st.markdown("""
<style>
    /* CSS Variables for Uniform Theme */
    :root {
        --primary-color: #4f46e5;
        --secondary-color: #3b82f6;
        --background-color: #ffffff;
        --surface-color: #f8fafc;
        --text-color: #1e293b;
        --muted-text-color: #64748b;
        --border-color: #e2e8f0;
        --success-color: #10b981;
        --warning-color: #f59e0b;
        --error-color: #ef4444;
    }

    /* Subtle Animations & Hover Effects */
    @media (prefers-reduced-motion: no-preference) {
        /* Container fade-in and hover lift */
        [data-testid="stVerticalBlockBorderWrapper"] {
            animation: fadeSlideUp 0.6s ease-out both;
            transition: transform 0.2s ease, box-shadow 0.2s ease !important;
        }
        
        [data-testid="stVerticalBlockBorderWrapper"]:hover {
            transform: translateY(-2px);
            box-shadow: 0 8px 16px rgba(0, 0, 0, 0.06) !important;
        }

        /* Staggered animation for containers */
        [data-testid="stVerticalBlockBorderWrapper"]:nth-child(1) { animation-delay: 0.1s; }
        [data-testid="stVerticalBlockBorderWrapper"]:nth-child(2) { animation-delay: 0.2s; }
        [data-testid="stVerticalBlockBorderWrapper"]:nth-child(3) { animation-delay: 0.3s; }
        [data-testid="stVerticalBlockBorderWrapper"]:nth-child(4) { animation-delay: 0.4s; }

        /* Button hover animation */
        .stButton > button {
            transition: all 0.2s ease !important;
        }
        .stButton > button:hover {
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.1) !important;
        }

        /* Metric hover */
        [data-testid="stMetric"] {
            transition: transform 0.2s ease;
        }
        [data-testid="stMetric"]:hover {
            transform: scale(1.02);
        }

        @keyframes fadeSlideUp {
            from {
                opacity: 0;
                transform: translateY(15px);
            }
            to {
                opacity: 1;
                transform: translateY(0);
            }
        }
    }

    /* Refined container styling */
    [data-testid="stVerticalBlockBorderWrapper"] {
        border-radius: 12px !important;
        padding: 8px !important;
    }

    /* Primary Button Color Override */
    .stButton > button[kind="primary"] {
        background-color: var(--primary-color) !important;
        border-color: var(--primary-color) !important;
        color: white !important;
    }
    
    .stButton > button[kind="primary"]:hover {
        background-color: var(--secondary-color) !important;
        border-color: var(--secondary-color) !important;
    }
</style>
""", unsafe_allow_html=True)



from pathlib import Path

# =========================================================
# 2. FILE PATHS
# =========================================================

BASE_DIR = Path(__file__).resolve().parent
PROJECT_DIR = BASE_DIR.parent
ML_DIR = PROJECT_DIR / "ml"

DATASET_PATH = ML_DIR / "SMSSpamCollection"
VECTORIZER_PATH = ML_DIR / "vectorizer.pkl"
MODEL_PATH = ML_DIR / "spam_model.pkl"


# =========================================================
# 3. DATA LOADING
# =========================================================

@st.cache_data
def load_dataset():

    data = pd.read_csv(
        DATASET_PATH,
        sep="\t",
        header=None,
        names=["label", "message"],
        encoding="utf-8"
    )

    # Convert labels
    # ham  -> 0
    # spam -> 1

    data["label"] = data["label"].map({
        "ham": 0,
        "spam": 1
    })

    data = data.dropna()

    return data


# =========================================================
# 4. LOAD TRAINED MODEL
# =========================================================

@st.cache_resource
def load_model():

    vectorizer = joblib.load(
        VECTORIZER_PATH
    )

    model = joblib.load(
        MODEL_PATH
    )

    return vectorizer, model


# =========================================================
# 5. LOAD DATASET AND MODEL
# =========================================================

try:

    data = load_dataset()

    vectorizer, model = load_model()

except FileNotFoundError as e:

    st.error(
        f"Required file was not found: {e.filename}"
    )

    st.info(
        "Make sure the dataset and trained .pkl files "
        "are present inside the ml folder."
    )

    st.stop()


# =========================================================
# 6. MODEL PERFORMANCE
# =========================================================

def evaluate_model(data, vectorizer, model):

    X = data["message"]
    y = data["label"]

    # Convert messages into vectors

    X_vectorized = vectorizer.transform(X)

    # Predict

    y_pred = model.predict(
        X_vectorized
    )

    # Metrics

    accuracy = accuracy_score(
        y,
        y_pred
    )

    precision = precision_score(
        y,
        y_pred,
        zero_division=0
    )

    recall = recall_score(
        y,
        y_pred,
        zero_division=0
    )

    f1 = f1_score(
        y,
        y_pred,
        zero_division=0
    )

    cm = confusion_matrix(
        y,
        y_pred
    )

    return (
        accuracy,
        precision,
        recall,
        f1,
        cm
    )


(
    accuracy,
    precision,
    recall,
    f1,
    cm
) = evaluate_model(
    data,
    vectorizer,
    model
)

# =========================================================
# 7. APPLICATION STYLING
# =========================================================

st.html("""
<style>

/* =====================================================
   THEME VARIABLES
   ===================================================== */

:root {
    --card-bg: var(--secondary-background-color);
    --text-primary: var(--text-color);
    --border-color: rgba(128, 128, 128, 0.25);
    --muted-text: rgba(128, 128, 128, 0.9);
}


/* =====================================================
   MAIN HEADER
   ===================================================== */

.main-header {

    background: linear-gradient(
        135deg,
        #1f4e79 0%,
        #2563eb 50%,
        #4f46e5 100%
    );

    padding: 30px 32px;

    border-radius: 20px;

    margin-bottom: 28px;

    box-shadow:
        0 8px 25px rgba(0, 0, 0, 0.15);
}


.header-content {

    display: flex;

    align-items: center;

    gap: 18px;
}


.header-icon {

    width: 64px;
    height: 64px;

    border-radius: 16px;

    background:
        rgba(255, 255, 255, 0.16);

    display: flex;

    align-items: center;

    justify-content: center;

    font-size: 32px;

    flex-shrink: 0;
}


.header-title {

    color: white;

    font-size: 30px;

    font-weight: 700;

    line-height: 1.2;

    margin: 0;
}


.header-subtitle {

    color:
        rgba(255, 255, 255, 0.82);

    font-size: 14px;

    margin-top: 6px;
}


.header-badge {

    display: inline-block;

    margin-top: 18px;

    padding: 6px 12px;

    border-radius: 20px;

    background:
        rgba(255, 255, 255, 0.15);

    color: white;

    font-size: 12px;

    font-weight: 600;
}


/* =====================================================
   SECTION CARD
   ===================================================== */

.section-card {

    background: var(--card-bg);

    border: 1px solid var(--border-color);

    border-radius: 16px;

    padding: 20px 22px;

    margin-top: 24px;

    margin-bottom: 14px;

    box-shadow:
        0 4px 14px rgba(0, 0, 0, 0.05);
}


.section-title {

    color: var(--text-primary);

    font-size: 20px;

    font-weight: 700;

    margin-bottom: 5px;
}


.section-description {

    color: var(--muted-text);

    font-size: 14px;

    line-height: 1.5;
}


/* =====================================================
   ANALYZER CARD
   ===================================================== */

.analyzer-card {

    background:
        linear-gradient(
            135deg,
            rgba(37, 99, 235, 0.08),
            rgba(79, 70, 229, 0.12)
        );

    border: 1px solid
        rgba(99, 102, 241, 0.25);

    border-radius: 18px;

    padding: 24px;

    margin-top: 28px;

    margin-bottom: 12px;
}


.analyzer-title {

    color: var(--text-primary);

    font-size: 22px;

    font-weight: 700;

    margin-bottom: 5px;
}


.analyzer-description {

    color: var(--muted-text);

    font-size: 14px;

    line-height: 1.5;
}


.analyzer-badge {

    display: inline-block;

    margin-top: 14px;

    padding: 5px 10px;

    border-radius: 20px;

    background:
        rgba(79, 70, 229, 0.12);

    color: #818cf8;

    font-size: 12px;

    font-weight: 600;
}


/* =====================================================
   RESULT CARD
   ===================================================== */

.result-card {

    border-radius: 16px;

    padding: 22px;

    margin-top: 22px;

    border: 1px solid var(--border-color);

    background: var(--card-bg);
}


.result-title {

    color: var(--text-primary);

    font-size: 22px;

    font-weight: 700;
}


.result-subtitle {

    color: var(--muted-text);

    font-size: 14px;

    margin-top: 5px;
}


/* =====================================================
   FOOTER
   ===================================================== */

.footer {

    text-align: center;

    color: var(--muted-text);

    font-size: 12px;

    margin-top: 40px;

    margin-bottom: 20px;
}

</style>
""")


# =========================================================
# 8. HEADER
# =========================================================

st.html("""
<div class="main-header">

    <div class="header-content">

        <div class="header-icon">
            📱
        </div>

        <div>

            <div class="header-title">
                SMS Spam Detector
            </div>

            <div class="header-subtitle">
                Machine Learning based SMS classification
            </div>

        </div>

    </div>

    <div class="header-badge">
        🤖 Multinomial Naive Bayes • NLP
    </div>

</div>
""")


# =========================================================
# 9. DATASET INFORMATION
# =========================================================

st.html("""
<div class="section-card">

    <div class="section-title">
        📊 Dataset Information
    </div>

    <div class="section-description">
        Overview of the SMS messages used to train and evaluate
        the classification model.
    </div>

</div>
""")


col1, col2, col3 = st.columns(3)


with col1:

    st.metric(
        "Total Messages",
        f"{len(data):,}"
    )


with col2:

    st.metric(
        "Ham Messages",
        f"{(data['label'] == 0).sum():,}"
    )


with col3:

    st.metric(
        "Spam Messages",
        f"{(data['label'] == 1).sum():,}"
    )


# =========================================================
# 10. MODEL PERFORMANCE
# =========================================================

st.html("""
<div class="section-card">

    <div class="section-title">
        📈 Model Performance
    </div>

    <div class="section-description">
        Evaluation results of the Multinomial Naive Bayes
        classifier.
    </div>

</div>
""")


col1, col2, col3, col4 = st.columns(4)


with col1:

    st.metric(
        "Accuracy",
        f"{accuracy * 100:.2f}%"
    )


with col2:

    st.metric(
        "Precision",
        f"{precision * 100:.2f}%"
    )


with col3:

    st.metric(
        "Recall",
        f"{recall * 100:.2f}%"
    )


with col4:

    st.metric(
        "F1 Score",
        f"{f1 * 100:.2f}%"
    )


with st.expander("View Confusion Matrix"):

    # Convert to long format for Altair heatmap
    cm_df = pd.DataFrame(cm, index=["Ham", "Spam"], columns=["Ham", "Spam"])
    cm_df = cm_df.reset_index().melt(id_vars="index", var_name="Predicted", value_name="Count")
    cm_df.rename(columns={"index": "Actual"}, inplace=True)
    
    # Create Altair heatmap
    base = alt.Chart(cm_df).encode(
        x=alt.X('Predicted:O', title='Predicted Label', axis=alt.Axis(labelAngle=0)),
        y=alt.Y('Actual:O', title='Actual (True) Label', sort='descending')
    )
    
    # Heatmap rects with primary-colored scale (blues)
    heatmap = base.mark_rect().encode(
        color=alt.Color('Count:Q', scale=alt.Scale(scheme='blues'), legend=None)
    )
    
    # Text labels inside cells
    text = base.mark_text(baseline='middle', fontSize=14, fontWeight='bold').encode(
        text='Count:Q',
        color=alt.condition(
            alt.datum.Count > cm_df['Count'].max() / 2,
            alt.value('white'),
            alt.value('black')
        )
    )
    
    chart = (heatmap + text).properties(
        height=300,
        title='Confusion Matrix'
    ).configure_axis(
        labelFontSize=13,
        titleFontSize=14,
        titlePadding=10
    ).configure_title(
        fontSize=18,
        anchor='middle',
        offset=15
    )
    
    st.altair_chart(chart, use_container_width=True)

    # Metrics Summary
    total = cm.sum()
    correct = cm.trace()
    incorrect = total - correct
    
    st.markdown("##### Prediction Summary")
    col_tot, col_cor, col_inc, col_acc = st.columns(4)
    col_tot.metric("Total", f"{total:,}")
    col_cor.metric("Correct", f"{correct:,}")
    col_inc.metric("Incorrect", f"{incorrect:,}")
    col_acc.metric("Accuracy", f"{(correct/total)*100:.1f}%")


# =========================================================
# 11. SMS ANALYZER
# =========================================================

st.markdown("<br>", unsafe_allow_html=True)

with st.container(border=True):
    st.markdown("### 🔍 Analyze an SMS Message")
    st.markdown("Enter a message below and let the machine learning model determine whether it is spam or legitimate.")
    
    user_input = st.text_area(
        "SMS Message",
        placeholder=(
            "Example:\n"
            "Congratulations! You have won a prize. "
            "Click the link to claim it."
        ),
        height=140,
        label_visibility="collapsed"
    )

    analyze_clicked = st.button(
        "🔍 Analyze Message",
        use_container_width=True,
        type="primary"
    )

# =========================================================
# 12. SUSPICIOUS KEYWORDS
# =========================================================

security_triggers = [
    "free", "winner", "won", "prize", "urgent", "claim",
    "reward", "cash", "offer", "click", "verify", "account",
    "password", "bank", "credit", "limited", "congratulations",
    "http://", "https://", "www."
]

def find_suspicious_keywords(message):
    message_lower = message.lower()
    return [kw for kw in security_triggers if kw in message_lower]

# =========================================================
# 13. MESSAGE ANALYSIS
# =========================================================

if analyze_clicked:

    if not user_input.strip():

        st.warning(
            "Please enter an SMS message."
        )

    else:

        # -------------------------------------------------
        # TEXT → NUMBERS
        # -------------------------------------------------

        user_vector = vectorizer.transform(
            [user_input]
        )


        # -------------------------------------------------
        # PREDICTION
        # -------------------------------------------------

        prediction = model.predict(
            user_vector
        )[0]


        # -------------------------------------------------
        # PROBABILITY
        # -------------------------------------------------

        probabilities = model.predict_proba(
            user_vector
        )[0]


        ham_probability = probabilities[0]

        spam_probability = probabilities[1]


        # -------------------------------------------------
        # SUSPICIOUS KEYWORDS
        # -------------------------------------------------

        suspicious_keywords = find_suspicious_keywords(
            user_input
        )


        # -------------------------------------------------
        # RESULT & VISUALIZATION
        # -------------------------------------------------
        
        st.markdown("---")
        
        if prediction == 1:
            st.error("### 🚨 Spam Message\nThe model classified this message as **Spam**.")
        else:
            st.success("### ✅ Legitimate Message\nThe model classified this message as **Ham (Legitimate)**.")

        # Display Probabilities
        st.markdown("#### Confidence Scores")
        col_spam, col_ham = st.columns(2)
        
        with col_spam:
            st.metric("Spam Probability", f"{spam_probability * 100:.2f}%")
            st.progress(float(spam_probability))
            
        with col_ham:
            st.metric("Ham Probability", f"{ham_probability * 100:.2f}%")
            st.progress(float(ham_probability))

        # -------------------------------------------------
        # SUSPICIOUS KEYWORDS DISPLAY
        # -------------------------------------------------

        if suspicious_keywords:
            st.warning(f"⚠️ **Suspicious Keywords Detected:** {', '.join(suspicious_keywords)}")
        elif prediction == 1:
            st.info("ℹ️ No explicitly listed suspicious keywords found, but context suggests spam.")





# =========================================================
# 14. SAMPLE DATASET
# =========================================================

with st.container(border=True):
    st.markdown("### 📋 Sample Dataset")
    st.markdown("Preview of messages from the dataset used by the model.")

with st.expander(f"View Sample Messages ({len(data.head(10))} sample messages)"):

    sample_data = data.head(10).copy()

    # Create a responsive 2-column grid for the cards
    cols = st.columns(2)
    
    for i, (_, row) in enumerate(sample_data.iterrows()):
        # Map label: 0 -> Ham, 1 -> Spam
        label_text = "Spam" if row["label"] == 1 else "Ham"
        msg_text = row["message"]
        
        # Apply theme-aware colors for the status badge
        if label_text == "Spam":
            badge_color = "var(--error-color)"
            badge_bg = "rgba(239, 68, 68, 0.12)"
        else:
            badge_color = "var(--success-color)"
            badge_bg = "rgba(16, 185, 129, 0.12)"
            
        col = cols[i % 2]
        
        with col.container(border=True):
            st.markdown(f"""
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 12px;">
                <span style="font-size: 13px; color: var(--muted-text-color); font-weight: 600; text-transform: uppercase;">Message #{i + 1}</span>
                <span style="background-color: {badge_bg}; color: {badge_color}; padding: 4px 12px; border-radius: 12px; font-size: 12px; font-weight: 700; border: 1px solid {badge_color}40;">
                    {label_text.upper()}
                </span>
            </div>
            <div style="font-size: 15px; color: var(--text-color); line-height: 1.6; word-wrap: break-word; padding-bottom: 4px;">
                "{msg_text}"
            </div>
            """, unsafe_allow_html=True)


# =========================================================
# 15. FOOTER
# =========================================================

st.html("""
<div class="footer">

    SMS Spam Detector • Machine Learning & NLP

</div>
""")