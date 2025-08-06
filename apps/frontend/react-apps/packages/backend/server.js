require('dotenv').config();
const swaggerJsdoc = require('swagger-jsdoc');
const swaggerUi = require('swagger-ui-express');
const express = require('express');
const cors = require('cors');

const app = express();

// Enable CORS for localhost:3000 (or all origins * for dev)
app.use(cors({
    origin: 'http://localhost:3000',
    credentials: true
}));

app.use(express.json()); // Required to parse JSON request bodies

const loadRoutes = require('./loadRoutes');
loadRoutes(app);

// Swagger setup
const swaggerOptions = {
    definition: {
        openapi: '3.0.0',
        info: {
            title: 'Cloud Services API',
            version: '1.0.0',
            description: 'Automatically generated API docs for the backend API for the fusion and xyte cloud services'
        },
        components: {
            securitySchemes: {
                bearerAuth: {
                    type: 'http',
                    scheme: 'bearer',
                    bearerFormat: 'JWT'
                }
            }
        }
    },
    apis: ['./routes/**/*.js'], // points to route files with JSDoc comments
};

const swaggerSpec = swaggerJsdoc(swaggerOptions);

app.use('/api-docs', swaggerUi.serve, swaggerUi.setup(swaggerSpec));

const PORT = process.env.PORT || 3001;
app.listen(PORT, () => console.log(`Backend service running at http://localhost:${PORT}`));
