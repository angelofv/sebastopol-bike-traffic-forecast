from __future__ import annotations

import os

import mlflow.sklearn
import streamlit as st

# ────────────────────── CONFIG ──────────────────────
st.set_page_config(
    page_title="ML Project",
    page_icon="🤖",
    layout="centered",
)

# ───────────── Sidebar – profile ──────────────
PROFILE: dict[str, str] = {
    "name": "Angelo F.V.",
    "description": "Data Scientist & ML Engineer 🛠️",
    "location": "Paris, France",
    "avatar": "https://i.postimg.cc/6pDXBGFy/DSC0064-1.jpg",
}
LINKS: dict[str, str] = {
    "LinkedIn": "https://linkedin.com/in/angelo-fv/",
    "GitHub": "https://github.com/angelofv",
    "Email": "mailto:angelo.fv@outlook.fr",
}

with st.sidebar:
    if PROFILE["avatar"]:
        st.image(PROFILE["avatar"], width=130)
    st.title(PROFILE["name"])
    st.caption(f"{PROFILE['description']}  \n📍 {PROFILE['location']}")
    inline = " · ".join(f"[{link}]({url})" for link, url in LINKS.items() if url)
    if inline:
        st.markdown(inline)

# ───────────── Landing page ──────────────
st.title("My ML Project")
st.write("A concise project description.")

docs_url = "a"
repo_url = "b"

if docs_url or repo_url:
    st.subheader("Resources")
    if docs_url:
        st.markdown(f"📄 **Docs** – Full reference & examples [here]({docs_url}).")
    if repo_url:
        st.markdown(
            f"🐙 **Repo** – Browse the source code on GitHub [here]({repo_url})."
        )

st.markdown("---")


# ─────────── Load model from ML Registry ───────────
@st.cache_resource
def load_model():
    """Load the model from the MLflow Model Registry."""
    tracking_uri = os.getenv(
        "MLFLOW_REMOTE_URI", os.getenv("MLFLOW_TRACKING_URI", "http://localhost:5000")
    )
    # Load the model from the Model Registry
    mlflow.set_tracking_uri(tracking_uri)
    model_name = "IrisClassifier"
    model_version = "latest"
    model_uri = f"models:/{model_name}/{model_version}"
    return mlflow.sklearn.load_model(model_uri)


m = load_model()

# ───────────── Model explorer ──────────────
FEATURES: list[str] = [
    "sepal length (cm)",
    "sepal width (cm)",
    "petal length (cm)",
    "petal width (cm)",
]
st.header("Model Explorer")
with st.form("prediction_form"):
    st.write("Enter feature values:")
    values = [st.number_input(f, value=0.0, format="%.3f") for f in FEATURES]
    if st.form_submit_button("Predict"):
        try:
            with st.spinner("Predicting…"):
                pred = m.predict([values])[0]
            st.success(f"Prediction: {pred}")
        except Exception as exc:
            st.error(f"Prediction failed: {exc}")
