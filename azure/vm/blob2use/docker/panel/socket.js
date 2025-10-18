#!/usr/bin/env node
'use strict';

const express = require('express');
const fs = require('fs');
const http = require('http');
const { lstatSync, unlinkSync, chmodSync, existsSync, rmSync } = fs;
const resetServices = require('./lib/docker-reset');

const SOCKET_PATH    = '/tmp/mapineda48.sock';
const SECRET_TOKEN   = process.env.WEBHOOK_SECRET 
                     || 'slK7gFsD8nV0qPxYwz2NBRmhXtL5eOc9uYArMjiWQHEpTGbvKdCU1JZxfLo3Mgq6';

const app = express();
app.use(express.json());

// 🧹 Elimina cualquier residuo en SOCKET_PATH antes de levantar el servidor
if (existsSync(SOCKET_PATH)) {
  try {
    const stat = lstatSync(SOCKET_PATH);
    if (stat.isSocket()) {
      unlinkSync(SOCKET_PATH);
    } else {
      console.warn(`⚠️ ${SOCKET_PATH} no es un socket. Eliminando...`);
      rmSync(SOCKET_PATH, { recursive: true, force: true });
    }
  } catch (err) {
    console.error(`❌ Error limpiando ${SOCKET_PATH}:`, err.message);
    process.exit(1);
  }
}

// 🔐 Middleware para validar token en la ruta
function authMiddleware(req, res, next) {
  const token = req.params.token;
  if (!SECRET_TOKEN || token !== SECRET_TOKEN) {
    return res.status(403).json({ error: 'Token inválido' });
  }
  next();
}

// 📦 Webhook para Docker Hub
app.post('/:token/dockerhub', authMiddleware, async (req, res) => {
  const repo = req.body?.repository?.repo_name;
  const tag  = req.body?.push_data?.tag;
  const image = repo && tag ? `${repo}:${tag}` : null;

  if (!image) {
    return res.status(400).json({ error: 'Payload inválido o sin imagen' });
  }

  // Confirmamos recepción antes de procesar en background
  res.status(200).json({ ok: true, image });

  try {
    await resetServices(image);
  } catch (err) {
    console.error('❌ Error durante resetServices():', err);
  }
});

// 🔌 Arranca el servidor sobre el socket UNIX
const server = http.createServer(app);
server.listen(SOCKET_PATH, () => {
  chmodSync(SOCKET_PATH, 0o766);
  console.log(`🟢 Webhook escuchando en ${SOCKET_PATH}`);
});
