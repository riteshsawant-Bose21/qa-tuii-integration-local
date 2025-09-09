# Fusion Apps Monorepo

This is a Moon-powered fusion-monorepo that contains both frontend, backend & firmware applications, configured with a unified toolchain for consistent developer experience.
Each project resides in its own dedicated folder and is maintained, tested, and deployed by it's respective workflow. After all applications are successfully built and tested, a Yocto image build is triggered to integrate the latest artifacts into a complete system image.

## Repository Structure

<pre lang="text"><code> ``` / ├── apps/ │ ├── cloud-backend/ # Bose-Professional Cloud Backend Services │ ├── firmware-apps/ # Firmware Applications │ └── frontend/ # Fusion Launcher & Cloud UI Application ├── .github/ │ ├── workflows/ # GitHub Actions CI/CD workflows │ ├── reusable-actions/ # Reusable GitHub Actions │ └── CODEOWNERS # Code ownership configuration ├── .moon/ # Moon monorepo tool projects configuration └── README.md ``` </code></pre>

---

## Code Ownership

Each folder is assigned to specific teams or individuals using the `.github/CODEOWNERS` file.

| Project Folder                 | Code Owners               |
|--------------------------------|---------------------------|
| `projects/cloud-backend`       | `@backend-team`           |
| `projects/firmware-apps`       | `@frontend-team`          |
| `projects/frontend`            | `@mobile-team`            |

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
