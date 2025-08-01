const express = require("express");
const router = express.Router();
const requireAuth = require("../../middleware/requireAuth");
const xyte = require("../../xyte/xyteClient");
const { sendResponse } = require("../../utils/sendResponse");
const { STATUS_FLAG } = require("../../utils/constants");
/**
 * @swagger
 * /api/v1/organization:
 *   get:
 *     summary: Retrieve organization information from Xyte
 *     tags: [Organization]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Organization information retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 id:
 *                   type: string
 *                   example: "org-1234"
 *                 name:
 *                   type: string
 *                   example: "Main Organization"
 *                 createdAt:
 *                   type: string
 *                   format: date-time
 *                   example: "2024-01-01T00:00:00Z"
 *       401:
 *         description: Unauthorized (missing or invalid token)
 *       500:
 *         description: Failed to retrieve organization information
 */

// GET /organization — Get organization info from Xyte
router.get("/", requireAuth, async (req, res) => {
  try {
    const response = await xyte.get("/info");
    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Organization information retrieved successfully",
      response.data
    );
  } catch (err) {
    console.error("Error fetching organization:", err.message);
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error fetching organization information",
      err.message
    );
  }
});

module.exports = router;
