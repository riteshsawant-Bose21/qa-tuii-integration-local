const fs = require('fs');
const path = require('path');

function loadRoutes(app) {
  const routesBasePath = path.join(__dirname, 'routes');

  const versions = fs.readdirSync(routesBasePath);

  versions.forEach(version => {
    const versionPath = path.join(routesBasePath, version);

    if (fs.lstatSync(versionPath).isDirectory()) {
      const files = fs.readdirSync(versionPath);

      files.forEach(file => {
        const filePath = path.join(versionPath, file);
        const route = require(filePath);

        if (typeof route !== 'function') {
          console.warn(`Skipping ${file} in ${version}: not a valid router`);
          return;
        }

        // Mount route at /api/v1/routeName
        const routeName = file.replace('.js', '');
        app.use(`/api/${version}/${routeName}`, route);
      });
    }
  });
}

module.exports = loadRoutes;
