import torch
import torch.nn as nn
import torch.optim as optim
from torch.utils.data import DataLoader
from torchvision import datasets, transforms
import json
import os
from model import Autoencoder

with open('config.json') as f: config = json.load(f)
os.makedirs(config['ckpt_folder'], exist_ok=True)

train_loader = DataLoader(datasets.MNIST('./data', train=True, download=True, 
    transform=transforms.ToTensor()), batch_size=config['batch_size'], shuffle=True)

model = Autoencoder()
optimizer = optim.Adam(model.parameters(), lr=config['learning_rate'])

for epoch in range(config['epochs']):
    for data, target in train_loader:
        optimizer.zero_grad()
        recon, class_out = model(data)
        loss = nn.MSELoss()(recon, data) + nn.CrossEntropyLoss()(class_out, target)
        loss.backward()
        optimizer.step()
    print(f'Epoch {epoch+1}/{config["epochs"]}, Loss: {loss.item():.4f}')

torch.save(model.state_dict(), config['ckpt_path'])
print(f'Model saved to {config["ckpt_path"]}')