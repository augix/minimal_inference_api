from flask import Flask, request, jsonify
import torch
import torch.nn.functional as F
from torchvision import transforms
import base64
import io
from PIL import Image
import json
from model import Autoencoder

app = Flask(__name__)
with open('config.json') as f: config = json.load(f)
model = Autoencoder()
model.load_state_dict(torch.load(config['ckpt_path'], map_location='cpu', weights_only=True))
model.eval()

@app.route('/predict', methods=['POST'])
def predict():
    try:
        img = Image.open(io.BytesIO(base64.b64decode(request.json['image']))).convert('L').resize((28, 28))
        x = transforms.ToTensor()(img).unsqueeze(0)
        with torch.no_grad():
            recon, out = model(x)
            probs = F.softmax(out, dim=1)
            pred, conf = torch.argmax(probs, dim=1).item(), probs[0].max().item()
        recon_img = Image.fromarray((recon.squeeze().numpy() * 255).astype('uint8'))
        buffer = io.BytesIO()
        recon_img.save(buffer, format='PNG')
        return jsonify({'predicted_class': pred, 'confidence': conf, 
                       'reconstructed_image': base64.b64encode(buffer.getvalue()).decode()})
    except Exception as e:
        return jsonify({'error': str(e)}), 400

@app.route('/health', methods=['GET'])
def health():
    return jsonify({'status': 'healthy'})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=config['api_port'])