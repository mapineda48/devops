'use strict';

const { exec } = require('child_process');
const { promisify } = require('util');
const Docker = require('dockerode');

const docker = new Docker({ socketPath: '/var/run/docker.sock' });
const execAsync = promisify(exec);

const ALLOWED_IMAGES = ['mapineda48/msgpack-vite-agape-app:latest'];
const COMPOSE_FILE = '/mnt/deploy/mapineda48.vm/docker/compose/docker-compose.yml';

/**
 * Descarga y reinicia los servicios afectados si la imagen ha cambiado.
 * @param {string} image - Nombre completo de la imagen con tag.
 */
module.exports = async function resetServices(image) {
  if (!ALLOWED_IMAGES.includes(image)) {
    console.error(`❌ Imagen no permitida: ${image}`);
    return;
  }

  console.log(`↻ Verificando si la imagen cambió: ${image}`);

  // Imagen antes del pull
  const beforeList = await docker.listImages({ filters: { reference: [image] } });
  const before = beforeList[0];

  // Tirar la nueva versión
  await pullImage(image);

  // Imagen después del pull
  const afterList = await docker.listImages({ filters: { reference: [image] } });
  const after = afterList[0];

  // Si no cambió, no hacemos nada
  if (before?.Id === after?.Id) {
    console.log('→ La imagen está sincronizada, no se reinician servicios.');
    return;
  }

  console.log('✓ Imagen actualizada, reiniciando servicios...');

  // Listamos todos los contenedores y filtramos los que usan la imagen antigua o la misma referencia
  const allContainers = await docker.listContainers({ all: true });
  const oldImageId = before?.Id?.replace('sha256:', '');
  const matching = allContainers.filter(c =>
    c.ImageID === oldImageId || c.Image === image
  );

  console.log(`🔍 Contenedores encontrados: ${matching.length}`);

  // Extraemos los nombres de servicio de Docker‑Compose
  const services = new Set();
  for (const c of matching) {
    const svc = c.Labels?.['com.docker.compose.service'];
    if (svc) {
      services.add(svc);
    } else {
      console.warn(`⚠️ Contenedor sin label compose.service: ${c.Names[0]}`);
    }
  }

  // Recreamos cada servicio
  for (const svc of services) {
    await recreateService(svc);
  }
};

// --- Funciones auxiliares ---

async function pullImage(image) {
  return new Promise((resolve, reject) => {
    docker.pull(image, (err, stream) => {
      if (err) return reject(err);
      docker.modem.followProgress(
        stream,
        (err) => (err ? reject(err) : resolve()),
        event => {
          if (event.status) {
            process.stdout.write(`→ ${event.status} ${event.progress || ''}\n`);
          }
        }
      );
    });
  });
}

async function recreateService(serviceName) {
  try {
    await execAsync(`docker compose -f ${COMPOSE_FILE} rm -sf ${serviceName}`);
    console.log(`✓ Servicio ${serviceName} eliminado`);
  } catch (err) {
    console.warn(`⚠️ No se pudo eliminar ${serviceName}: ${err.message}`);
  }

  try {
    await execAsync(`docker compose -f ${COMPOSE_FILE} up -d ${serviceName}`);
    console.log(`✓ Servicio ${serviceName} levantado`);
  } catch (err) {
    console.error(`❌ Error levantando ${serviceName}: ${err.message}`);
  }
}
