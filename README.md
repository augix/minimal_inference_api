# MNIST Autoencoder Demo

A minimal demo for MNIST autoencoder with reconstruction and classification capabilities.

## Files

- `config.json` - Configuration file with checkpoint paths and ports
- `model.py` - Autoencoder model architecture
- `train.py` - Training script for the model
- `inference_api.py` - Flask API for inference (port 8001)
- `web_ui.py` - Streamlit web interface (port 8051)
- `requirements.txt` - Python dependencies

## Usage

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Train the model:
```bash
python train.py
```

3. Start the inference API:
```bash
python inference_api.py
```

4. Start the web UI (in another terminal):
```bash
streamlit run web_ui.py --server.port 8051
```

5. Open your browser and go to `http://localhost:8051`


## Features

- Autoencoder for image reconstruction
- Classification head for digit recognition
- REST API for inference
- Web UI with example images and file upload
- Model weights saved to `./ckpt/last.ckpt`