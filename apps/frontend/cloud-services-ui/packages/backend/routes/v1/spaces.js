const express = require("express");
const router = express.Router();
const requireAuth = require("../../middleware/requireAuth");
const xyte = require("../../xyte/xyteClient");
const { sendResponse } = require("../../utils/sendResponse");
const { STATUS_FLAG } = require("../../utils/constants");
/**
 * @swagger
 * /api/v1/spaces:
 *   get:
 *     summary: Get list of spaces
 *     tags: [Spaces]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of spaces
 *       401:
 *         description: Unauthorized
 */

// GET /spaces — List spaces
router.get("/", requireAuth, async (req, res) => {
  try {
    const response = await xyte.get("/spaces");
    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Spaces retrieved successfully",
      response.data
    );
  } catch (err) {
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error fetching spaces",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/spaces:
 *   post:
 *     summary: Create a new space
 *     tags: [Spaces]
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
 *                 example: "Main Office"
 *               parent_id:
 *                 type: integer
 *                 nullable: true
 *                 example: 1234
 *     responses:
 *       201:
 *         description: Space created
 *       400:
 *         description: Missing required fields
 *       401:
 *         description: Unauthorized
 */

// POST /spaces — Create space
router.post("/", requireAuth, async (req, res) => {
  try {
    const { name, parent_id } = req.body;
    if (!name) {
      return sendResponse(
        res,
        400,
        STATUS_FLAG.ERROR,
        "Name is required to create a space"
      );
    }

    const response = await xyte.post("/spaces", {
      name,
      parent_id: parent_id || null,
    });

    sendResponse(
      res,
      201,
      STATUS_FLAG.SUCCESS,
      "Space created successfully",
      response.data
    );
  } catch (err) {
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error creating space",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/spaces:
 *   put:
 *     summary: Update a space
 *     tags: [Spaces]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - id
 *             properties:
 *               id:
 *                 type: integer
 *                 example: 5678
 *               name:
 *                 type: string
 *                 nullable: true
 *                 example: "Updated Conference Room"
 *               parent_id:
 *                 type: integer
 *                 nullable: true
 *                 example: 9876
 *     responses:
 *       200:
 *         description: Space updated
 *       400:
 *         description: Missing ID
 *       401:
 *         description: Unauthorized
 */

// PUT /spaces — Update space
router.put("/", requireAuth, async (req, res) => {
  try {
    const { id, name, parent_id } = req.body;
    if (!id) {
      return sendResponse(
        res,
        400,
        STATUS_FLAG.ERROR,
        "ID is required to update a space"
      );
    }

    const response = await xyte.put(`/spaces/${id}`, {
      name,
      parent_id,
    });

    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Space updated successfully",
      response.data
    );
  } catch (err) {
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error updating space",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/spaces/{id}:
 *   delete:
 *     summary: Delete a space
 *     tags: [Spaces]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         schema:
 *           type: integer
 *         required: true
 *         description: Space ID to delete
 *     responses:
 *       204:
 *         description: Space deleted successfully
 *       400:
 *         description: Missing or invalid ID
 *       401:
 *         description: Unauthorized
 */
// DELETE /spaces/:id — Delete space
router.delete("/:id", requireAuth, async (req, res) => {
  try {
    const { id } = req.params;

    const response = await xyte.delete(`/spaces/${id}`);
    if (response.status === 204) {
      return sendResponse(
        res,
        204,
        STATUS_FLAG.SUCCESS,
        "Space deleted successfully"
      );
    } else {
      return sendResponse(
        res,
        response.status,
        STATUS_FLAG.ERROR,
        "Error deleting space",
        response.data
      );
    }
  } catch (err) {
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error deleting space",
      err.message
    );
  }
});

module.exports = router;
