import streamlit as st, requests, base64, io, os, json
from PIL import Image

with open('config.json') as f: config = json.load(f)
api_url = f"http://localhost:{config['api_port']}"

st.title("MNIST Autoencoder Demo")

# Check if the API is healthy
try:
    r = requests.get(f"{api_url}/health", timeout=2)
    st.success("🟢 API is healthy" if r.ok and r.json().get("status","").lower()=="healthy" else f"🔴 API unhealthy: {r.text}")
except Exception as e:
    st.error(f"🔴 API not reachable: {e}")

# Get example images
def get_example_images():
    files = [f for f in os.listdir("examples") if f.lower().endswith(('.png','.jpg','.jpeg'))]
    return [os.path.join("examples", f) for f in sorted(files)[:3]]

# Show example images
def show_examples():
    imgs = get_example_images()
    cols = st.columns(len(imgs))
    for i, (col, path) in enumerate(zip(cols, imgs)):
        with col:
            img = Image.open(path).convert('L').resize((28,28))
            st.image(img, caption=f"Example {i+1}", width=100)
            if st.button(f"Use Example {i+1}"): st.session_state.img = img

# Handle upload
def handle_upload():
    up = st.file_uploader("Upload image", type=['png','jpg','jpeg'])
    if up: st.session_state.img = Image.open(up).convert('L').resize((28,28))

# Run inference
def run_inference():
    c1, c2 = st.columns(2)
    c1.image(st.session_state.img, caption="Input", width=200)
    if c2.button("🚀 Run Inference"):
        try:
            buf = io.BytesIO(); st.session_state.img.save(buf, format='PNG')
            img_b64 = base64.b64encode(buf.getvalue()).decode()
            r = requests.post(f"{api_url}/predict", json={'image': img_b64})
            if r.ok:
                res = r.json()
                recon = Image.open(io.BytesIO(base64.b64decode(res['reconstructed_image'])))
                c2.image(recon, caption="Reconstructed", width=200)
                c2.success(f"Class: {res['predicted_class']}, Confidence: {res['confidence']:.2%}")
            else:
                c2.error(f"API Error: {r.text}")
        except Exception as e:
            c2.error(f"Error: {e}")

# Show examples, handle upload, and run inference
show_examples()
handle_upload()
if 'img' in st.session_state: run_inference()