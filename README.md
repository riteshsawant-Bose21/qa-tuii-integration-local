# Fusion Apps Monorepo

This is a Moon-powered fusion-monorepo that contains both frontend, backend & firmware applications, configured with a unified toolchain for consistent developer experience.
Each project resides in its own dedicated folder and is maintained, tested, and deployed by it's respective workflow. After all applications are successfully built and tested, a Yocto image build is triggered to integrate the latest artifacts into a complete system image.

## Project Graph
<img width="1465" height="681" alt="image" src="https://github.com/user-attachments/assets/4b9277be-be6a-4c74-bdcf-38a6bd79b964" />


## Repository Structure

```
/
├── apps/
│   ├── cloud-backend/     # Bose-Professional Cloud Backend Services
│   ├── firmware-apps/     # Firmware Applications
│   └── frontend/          # Fusion Launcher & Cloud UI Application
├── .github/
│   ├── workflows/         # GitHub Actions CI/CD workflows
│   ├── reusable-actions/  # Reusable GitHub Actions
│   └── CODEOWNERS         # Code ownership configuration
├── libs/                  # Shared libraries across projects
├── .moon/                 # Moon monorepo tool projects configuration
└── README.md
```
---

## Branch Naming Conventions
```
| Branch Name       | Purpose                                                                 |
|-------------------|-------------------------------------------------------------------------|
| release/*         | Production-ready code, ready for deployment                             |
| develop           | Integration branch with latest tested features, leading to `release`    |
| feature/*         | New features in progress (e.g., `feature-login1234`)                    |
| bugfix/*          | Bug fixes during development/QA (e.g., `bugfix-navbar1213`)             |
| hotfix/*          | Urgent production patches (e.g., `hotfix-login-crash1414`)              |
```
---

## Branch Roles Explained

### `release`
- **Source:** Merged from `develop` after testing is complete
- **Purpose:** Contains code **ready for production**
- **Triggers:** **Production builds**
- **Restrictions:** No direct commits; only PR merges

### `develop`
- **Source:** Merged from `feature/*`, `bugfix/*`, and `hotfix/*`
- **Purpose:** **Integration branch** — staging and testing before production
- **Triggers:** **Staging/test builds**
- **Status:** Always kept in a deployable state

### `feature/*`
- **Naming convention:** `feature-<description><TICKET_NUMBER>`
- **Source:** Branched from `develop`
- **Purpose:** Isolated development of **new features**
- **Builds:** CI/CD builds are skipped unless PR to `develop` is opened
- **End:** Merged to `develop` via PR

### `bugfix/*`
- **Naming convention:** `bugfix-<description><TICKET_NUMBER>`
- **Source:** Branched from `develop`
- **Purpose:** Fixing issues found during development or QA
- **Builds:** CI/CD builds are skipped unless PR to `develop` is opened
- **End:** Merged to `develop` via PR

### `hotfix/*`
- **Naming convention:** `hotfix-<description><TICKET_NUMBER>`
- **Source:** Branched from `release`
- **Purpose:** Urgent production patches
- **Builds:** Builds are skipped unless PR to `release` is opened
- **End:** Merged to `release`, then **back-merged to `develop`**

---

## CI/CD Build Rules
```
| Branch           | Build Trigger       | Condition                                     |
|------------------|---------------------|-----------------------------------------------|
| `release`        | ✅ Always           | Continuous deployment                         |
| `develop`        | ✅ Always           | Continuous integration (staging environment)  |
| `feature/*`      | ❌ Skipped          | ✅ Only if PR to `develop` is opened          |
| `bugfix/*`       | ❌ Skipped          | ✅ Only if PR to `develop` is opened          |
| `hotfix/*`       | ❌ Skipped          | ✅ Only if PR to `release` is opened          |
```
---

## Merge Flow Diagram
```
feature/*     ──┐
               ├──► develop ──┐
bugfix/*      ──┘             │
                             ├──► release ──► Production
hotfix/*      ───────────────┘       ▲
                                     │
                      back-merge to develop
```
---

## Code Ownership

Each folder is assigned to specific teams or individuals using the `.github/CODEOWNERS` file.

| Project Folder                 | Code Owners               |
|--------------------------------|---------------------------|
| `apps/cloud-backend`       | `@backend-team`           |
| `apps/firmware-apps`       | `@frontend-team`          |
| `apps/frontend`            | `@mobile-team`            |

Code owners are automatically requested for reviews when changes are made in their respective areas.

> **Note:** Update `.github/CODEOWNERS` whenever a new project is added or ownership changes.

---

## CI Workflow (GitHub Actions)

This monorepo uses **GitHub Actions** for continuous integration, in combination with **[Moon](https://moonrepo.dev/)** for task orchestration.

### Key Workflows:
- **Lint & Format:** Runs ESLint and Prettier checks on changed files.
- **Build:** Builds only the affected projects using `moon run` or project-specific build tasks.
- **Test:** Executes unit and integration tests for modified projects.
- **Type Check:** Verifies TypeScript or other type system correctness across affected codebases.
- **Deploy (optional):** Triggers deployment workflows for individual apps or services.
- **Image Build:** Once all projects are successfully built and tested, a **Yocto image build** is triggered to generate the system image using the latest artifacts.

### CI Implementation Details:

- Each project defines its CI logic in its own **reusable `action.yml`** file, located inside the project folder (e.g., `projects/web/.github/action.yml`).
- The root-level workflow in `.github/workflows/` acts as the orchestrator:
  - It **detects which projects are affected** using file path filters or Moon's task dependencies.
  - Only the reusable workflows for **updated project folders** are triggered.
- Task definitions are centralized in the `moon.yml` workspace configuration and individual `moon/project.yml` files per project.
- Moon handles caching, task dependencies, and concurrency, ensuring efficient and consistent builds across all projects.

This setup ensures fast, targeted CI runs that scale with the number of projects in the monorepo.

---

## Adding a New Project

To add a new project to this monorepo:

- Create Project Folder:  
  Inside the `apps/` directory, create a new folder with your project name:
  mkdir apps/<app-layer>/<your-project-name>

- Initialize the Project:  
  Use your preferred tooling (e.g., `npm init`, `create-react-app`, etc.).

- Add to CI: 
  To setup CI for your project please reach out to devops@boseprofessional.com or optionally follow below steps:

  - Define Moon Tasks:  
    In your project folder, create or update the `moon/project.yml` file to define tasks such as `build`, `lint`, `test`, and `typecheck`.  
    Refer to the [sample task file](apps/frontend/flutter-apps/moon.yml) for structure and conventions.

  - Create Reusable GitHub Action (Optional):  
    Define a `action.yml` file in your project’s `.github/` folder (e.g. `projects/<your-project>/.github/action.yml`) to encapsulate the project's CI steps. This makes it reusable by the main workflow dispatcher.

  - Hook Into Main CI Workflow:  
    The orchestrating workflow in `.github/workflows/` will automatically pick up your project if:
    - A change is detected in the project's codebase
    - The project has the necessary Moon tasks defined
    - A matching reusable action is in place (if used)

- Test Locally (Recommended):  
  Run Moon tasks locally with `moon run <project>:<task>` to validate behavior before pushing.


- Assign Code Owners:  
  Edit `.github/CODEOWNERS` and add the path + responsible GitHub username(s) or team(s): /projects/<your-project-name>/ @your-team

- Update README:  
  Consider updating this README to describe the new project.

---

## Tooling

This repo uses a unified and consistent developer experience powered by a combination of modern tools:

- **[Proto](https://moonrepo.dev/docs/proto/overview):**  
  Used to define and install a consistent toolchain across all environments (e.g., Node, PNPM, Go, Rust, etc.). Proto ensures all contributors and CI agents use the same versions of required tools.

- **[Yarn Workspaces](https://classic.yarnpkg.com/en/docs/workspaces/)** or **[pnpm](https://pnpm.io/):**  
  Monorepo package management with workspaces to link local dependencies and reduce duplication.

- **ESLint, Prettier, TypeScript:**  
  Shared configurations for linting, formatting, and type checking.

- **Yocto Toolchain:**  
  The Yocto build environment is prepared using **SDK installation scripts** executed on the respective build agents. These scripts install the cross-compilation toolchain and required environment to build the final system image after all projects have passed CI.

---

## Questions?

Reach out to the respective code owners or open an Jira issue [here](https://boseprofessional.atlassian.net/jira/software/c/projects/DEVOPS/boards/43?issueType=10009%2C10006).
