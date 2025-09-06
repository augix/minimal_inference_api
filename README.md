# MNIST Autoencoder Demo

A minimal demo for an MNIST autoencoder with both reconstruction and classification capabilities, featuring a REST API and a Streamlit web UI.

## Files

- `config.json` - Configuration file (checkpoint paths, batch size, learning rate, ports, etc.)
- `model.py` - Autoencoder model definition
- `train.py` - Model training script
- `inference_api.py` - Flask API for inference (port configurable via `config.json`)
- `web_ui.py` - Streamlit web interface (port configurable via `config.json`)
- `inference_service.sh` - Bash script to manage API and web UI processes
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

3. Start the inference API and web UI using the management script:
    ```bash
    ./inference_service.sh start
    ```
    - This will launch both the Flask API and the Streamlit web UI in the background.
    - Logs are saved to `api.log` and `web_ui.log`.

    *Alternatively, you can start them manually:*
    ```bash
    python inference_api.py
    ```
    and in another terminal:
    ```bash
    streamlit run web_ui.py --server.port 8051
    ```

4. Open your browser and go to `http://localhost:8051` (or the port specified in `config.json`).

## Features

- Autoencoder for MNIST image reconstruction
- Classification head for digit recognition
- REST API for inference (`/predict` and `/health` endpoints)
- Web UI with example images and file upload
- Model weights saved to the path specified in `config.json` (e.g., `./ckpt/last.ckpt`)
- Bash script for easy management of API and UI services