const axios = require('axios');

const xyte = axios.create({
  baseURL: 'https://hub.xyte.io/core/v1/organization',
  headers: {
    Authorization: `Bearer ${process.env.XYTE_API_KEY}`,
    'Content-Type': 'application/json'
  }
});

module.exports = xyte;
