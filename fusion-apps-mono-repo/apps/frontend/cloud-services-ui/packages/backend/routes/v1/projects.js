const express = require("express");
const db = require("../../db.js");
const router = express.Router();
const requireAuth = require("../../middleware/requireAuth.js");
const { sendResponse } = require("../../utils/sendResponse.js");
const { STATUS_FLAG } = require("../../utils/constants.js");

/**
 * @swagger
 * /api/v1/projects:
 *   get:
 *     summary: Get all projects for the authenticated user
 *     tags:
 *       - Projects
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: A list of projects
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   id:
 *                     type: integer
 *                     example: 1
 *                   name:
 *                     type: string
 *                     example: "My Project"
 *                   userId:
 *                     type: string
 *                     example: "test@gmail.com"
 *                   createdAt:
 *                     type: string
 *                     format: date-time
 *                     example: "2024-05-13T12:00:00.000Z"
 *                   updatedAt:
 *                     type: string
 *                     format: date-time
 *                     example: "2024-05-13T12:00:00.000Z"
 *                   metadata:
 *                     type: object
 *                     example: { "key": "value" }
 *       404:
 *         description: No projects found for the user
 *       500:
 *         description: Internal server error
 */

// GET /projects — Get all projects
router.get("/", requireAuth, (req, res) => {
  try {
    const userId = req.user.sub;

    db.all("SELECT * FROM projects WHERE userId = ?", [userId], (err, rows) => {
      if (err) {
        return sendResponse(
          res,
          500,
          STATUS_FLAG.ERROR,
          "Internal server error",
          err
        );
      }

      if (!rows || rows.length === 0) {
        return sendResponse(
          res,
          404,
          STATUS_FLAG.ERROR,
          "No projects found for the user",
          {}
        );
      }
      const projects = rows.map((row) => ({
        id: row.id,
        name: row.name,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        metadata: JSON.parse(row.metadata || "{}"),
      }));

      sendResponse(
        res,
        200,
        STATUS_FLAG.SUCCESS,
        "Projects retrieved successfully",
        { items: projects }
      );
    });
  } catch (err) {
    sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Internal server error",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/projects:
 *   post:
 *     summary: Create a new project
 *     tags:
 *       - Projects
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *             properties:
 *               name:
 *                 type: string
 *                 example: "My New Project"
 *               metadata:
 *                 type: object
 *                 example:
 *                   description: "This is an example project"
 *                   category: "test"
 *     responses:
 *       201:
 *         description: Project created successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   example: 1
 *                 name:
 *                   type: string
 *                   example: "My New Project"
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-05-13T10:00:00.000Z"
 *                 updatedAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-05-13T10:00:00.000Z"
 *                 metadata:
 *                   type: object
 *                   example:
 *                     description: "This is an example project"
 *       400:
 *         description: Missing name or invalid request body
 *       500:
 *         description: Internal server error
 */

// POST /projects — Create a new project
router.post("/", requireAuth, async (req, res) => {
  if (!req.body || typeof req.body !== "object") {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing request body",
      {}
    );
  }

  const { name, metadata } = req.body;

  if (!name) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing project name",
      {}
    );
  }

  try {
    // Check if the project name already exists
    db.get(
      "SELECT * FROM projects WHERE name = ? AND userId = ?",
      [name, req.user.sub],
      (err, row) => {
        if (err) {
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Internal server error",
            err
          );
        }
        if (row) {
          return sendResponse(
            res,
            409,
            STATUS_FLAG.ERROR,
            "Project with this name already exists",
            {}
          );
        }
        const userId = req.user.sub;
        const createdAt = new Date().toISOString();
        const updatedAt = createdAt;

        db.run(
          "INSERT INTO projects (userId, name, createdAt, updatedAt, metadata) VALUES (?, ?, ?, ?, ?)",
          [userId, name, createdAt, updatedAt, JSON.stringify(metadata)],
          function (err) {
            if (err) {
              return sendResponse(
                res,
                500,
                STATUS_FLAG.ERROR,
                "Internal server error",
                err
              );
            }

            if (!this.lastID) {
              return sendResponse(
                res,
                500,
                STATUS_FLAG.ERROR,
                "Failed to create project",
                {}
              );
            }

            const projectId = this.lastID;
            const newProject = {
              id: projectId,
              name,
              userId,
              createdAt,
              updatedAt,
              metadata: JSON.parse(metadata || "{}"),
            };
            return sendResponse(
              res,
              201,
              STATUS_FLAG.SUCCESS,
              "Project created successfully",
              newProject
            );
          }
        );
      }
    );
  } catch (err) {
    console.error("Error creating project:", err.message);
    return sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Internal server error",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/projects/{projectId}:
 *   get:
 *     summary: Get a specific project by ID
 *     tags:
 *       - Projects
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: projectId
 *         required: true
 *         schema:
 *           type: string
 *         description: The ID of the project to retrieve
 *     responses:
 *       200:
 *         description: Project found and returned
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: integer
 *                   example: 1
 *                 name:
 *                   type: string
 *                   example: "My Project"
 *                 userId:
 *                   type: string
 *                   example: "auth0|123456"
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-05-13T10:00:00.000Z"
 *                 updatedAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2025-05-13T10:00:00.000Z"
 *                 metadata:
 *                   type: object
 *                   example:
 *                     description: "This is the project metadata"
 *       404:
 *         description: Project not found
 *       500:
 *         description: Internal server error
 */

// GET /projects/:projectId — Get a project by ID
router.get("/:projectId", requireAuth, (req, res) => {
  const { projectId } = req.params;

  if (!projectId) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing project ID in path",
      {}
    );
  }

  try {
    const userId = req.user.sub;
    db.get(
      "SELECT * FROM projects WHERE id = ? AND userId = ?",
      [projectId, userId],
      (err, project) => {
        if (err) {
          console.error("Error fetching project:", err.message);
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Internal server error",
            err
          );
        }

        if (!project) {
          return sendResponse(
            res,
            404,
            STATUS_FLAG.ERROR,
            "Project not found",
            {}
          );
        }

        sendResponse(
          res,
          200,
          STATUS_FLAG.SUCCESS,
          "Project retrieved successfully",
          {
            id: project.id,
            name: project.name,
            userId: project.userId,
            createdAt: project.createdAt,
            updatedAt: project.updatedAt,
            metadata: JSON.parse(project.metadata || "{}"),
          }
        );
      }
    );
  } catch (err) {
    console.error("Error fetching project:", err.message);
    sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Internal server error",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/projects/{projectId}:
 *   patch:
 *     summary: Partially update a specific project by ID
 *     tags:
 *       - Projects
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: projectId
 *         required: true
 *         schema:
 *           type: string
 *         description: The ID of the project to update
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               name:
 *                 type: string
 *                 description: The name of the project (optional)
 *               metadata:
 *                 type: object
 *                 description: Metadata associated with the project (optional)
 *             additionalProperties: true
 *     responses:
 *       200:
 *         description: Project updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Project updated successfully"
 *       400:
 *         description: Missing required fields or invalid request body
 *       404:
 *         description: Project not found
 *       500:
 *         description: Internal server error
 */

// PATCH /projects/:projectId — Partially update a project by ID
router.patch("/:projectId", requireAuth, async (req, res) => {
  const { projectId } = req.params;

  if (!req.body || typeof req.body !== "object") {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing request body",
      {}
    );
  }

  const { name, metadata } = req.body;

  if (!name) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing project name",
      {}
    );
  }

  try {
    const userId = req.user.sub;
    const updatedAt = new Date().toISOString();

    db.run(
      "UPDATE projects SET name = ?, updatedAt = ?, metadata = ? WHERE id = ? AND userId = ?",
      [name, updatedAt, JSON.stringify(metadata), projectId, userId],
      function (err) {
        if (err) {
          console.error("Error updating project:", err.message);
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Internal server error",
            err
          );
        }

        if (this.changes === 0) {
          return sendResponse(
            res,
            404,
            STATUS_FLAG.ERROR,
            "Project not found",
            {}
          );
        }

        sendResponse(
          res,
          200,
          STATUS_FLAG.SUCCESS,
          "Project updated successfully",
          {
            id: projectId,
            name,
            userId,
            createdAt: new Date().toISOString(),
            updatedAt,
            metadata: JSON.parse(metadata || "{}"),
          }
        );
      }
    );
  } catch (err) {
    console.error("Error updating project:", err.message);
    sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Internal server error",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/projects/{projectId}:
 *   delete:
 *     summary: Delete a specific project by ID
 *     tags:
 *       - Projects
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: projectId
 *         required: true
 *         schema:
 *           type: string
 *         description: The ID of the project to delete
 *     responses:
 *       200:
 *         description: Project deleted successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "Project deleted successfully"
 *       404:
 *         description: Project not found
 *       500:
 *         description: Internal server error
 */

// DELETE /projects/:projectId — Delete a project by ID
router.delete("/:projectId", requireAuth, async (req, res) => {
  const { projectId } = req.params;

  try {
    const userId = req.user.sub;
    db.run(
      "DELETE FROM projects WHERE id = ? AND userId = ?",
      [projectId, userId],
      function (err) {
        if (err) {
          console.error("Error deleting project:", err.message);
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Internal server error",
            err
          );
        }

        if (this.changes === 0) {
          return sendResponse(
            res,
            404,
            STATUS_FLAG.ERROR,
            "Project not found",
            {}
          );
        }

        sendResponse(
          res,
          200,
          STATUS_FLAG.SUCCESS,
          "Project deleted successfully",
          {}
        );
      }
    );
  } catch (err) {
    console.error("Error deleting project:", err.message);
    sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Internal server error",
      err.message
    );
  }
});
//
// Export the router
module.exports = router;
