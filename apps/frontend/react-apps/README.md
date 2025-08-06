# cloud-services-ui
Web frontend for cloud services (xyte)

Below are instructions and notes for setting up your environment.

## Overview

- **Front-End**: A React (TypeScript) application that uses Material UI.
- **backend**: A simple express server which handles user auth and xyte API queries.
- **xyte-api**: A package to handle queries to the xyte API (NOT IN USE - backend package handles xyte queries)
- **shared-ui** A shared library for reusable React components.

We use **Yarn Workspaces** to manage dependencies across packages. Each sub-project can import from sibling libraries without duplicating code.

---

## Prerequisites

1. **Node.js** (preferably version ^23.x).
2. **Yarn** currently berry ^4.9.1 ('yarn set version berry')
3. **Git** for version control.

---

## Installation & Setup

1. **Clone** the repository:
   ```bash
   git clone https://github.com/BoseProfessional/cloud-services-ui.git
   ```

2. **Install** dependencies at the root:
   ```bash
   yarn install
   ```
   This will install for all packages in the repo.

3. **Initialize**:
   - (no environment variables at the moment)

4. **Build**:
   ```bash
   yarn build
   ```
   This will build all packages in the repo.

---

## Run a portal

1. **Start** the portal based on name:
   ```bash
   yarn start-customer
   ```

2. **Open** your browser to `http://localhost:3000`.

---

## Run the backend server

1. **Start** the backend API server
   ```bash
   yarn start-backend
   ```

2. **Open** your browser to `http://localhost:3001/api-docs` to view the backend API documentation.

---

## Additional Notes

- **Code Style**: We use ESLint + Prettier. See `.eslintrc.js` and `.prettierrc`.

