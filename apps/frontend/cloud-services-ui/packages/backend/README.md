# Running the server

## .env File

Create and update an .env file with your xyte organization API Key

(Optional) Set a new JWT secret for hashing tokens.

## Dependencies

Install dependencies:

yarn install

## Run

Run the following cmd to run the server:

node server.js

### CORS enabling

In the server.js file, there is the following line:

origin: 'http://localhost:3000',

You can set this to * in order to allow all CORS for dev purposes.

origin: '*'

## View API Docs

Once the server is running, navigate to the ServerURL/api-docs

New docs are generated when the server is ran (node server.js)

# Bruno Collection

The bruno_api_fusion_cloud directory contains the API collection which can be loaded in Bruno for separate testing.

