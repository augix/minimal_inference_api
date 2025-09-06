import streamlit as st
import requests
import base64
import io
from PIL import Image
import random
import json
import torchvision

# Load configuration and set API URL
with open('config.json') as f:
    config = json.load(f)
api_url = f"http://localhost:{config['api_port']}"

st.title("MNIST Autoencoder Demo")

# Utility function to get random MNIST examples (cached for performance)
@st.cache_data
def get_examples(seed):
    mnist = torchvision.datasets.MNIST('./data', train=False, download=True)
    rng = random.Random(seed)
    idx = rng.sample(range(len(mnist)), 3)
    return [mnist[i][0] for i in idx], [mnist[i][1] for i in idx]

def show_example_images():
    """Display three random MNIST example images with option to use one."""
    imgs, labels = get_examples(st.session_state.example_seed)
    cols = st.columns(3)
    for i, col in enumerate(cols):
        with col:
            st.image(imgs[i], caption=f"Label: {labels[i]}", width=100)
            if st.button(f"Use Example {i+1}"):
                st.session_state.img = imgs[i]

def handle_file_upload():
    """Handle user-uploaded image and store in session state."""
    uploaded = st.file_uploader("Upload image", type=['png', 'jpg', 'jpeg'])
    if uploaded:
        st.session_state.img = Image.open(uploaded).convert('L').resize((28, 28))

def run_inference_ui():
    """Display input image and run inference when requested."""
    c1, c2 = st.columns(2)
    c1.image(st.session_state.img, caption="Input", width=200)
    if c2.button("Run Inference"):
        try:
            # Prepare image for API
            buf = io.BytesIO()
            st.session_state.img.save(buf, format='PNG')
            img_b64 = base64.b64encode(buf.getvalue()).decode()
            # Send request to inference API
            r = requests.post(f"{api_url}/predict", json={'image': img_b64})
            if r.ok:
                res = r.json()
                # Show reconstructed image and prediction
                recon = Image.open(io.BytesIO(base64.b64decode(res['reconstructed_image'])))
                c2.image(recon, caption="Reconstructed", width=200)
                c2.success(f"Class: {res['predicted_class']}, Confidence: {res['confidence']:.2%}")
            else:
                c2.error(f"API Error: {r.text}")
        except Exception as e:
            c2.error(f"Error: {e}")

def main():
    # Initialize or refresh example seed for random images
    if 'example_seed' not in st.session_state:
        st.session_state.example_seed = random.randint(0, int(1e9))
    if st.button("🔄 Refresh Examples"):
        st.session_state.example_seed = random.randint(0, int(1e9))

    # Show example images and handle file upload
    show_example_images()
    handle_file_upload()

    # If an image is selected or uploaded, allow inference
    if 'img' in st.session_state:
        run_inference_ui()

if __name__ == "__main__":
    main()