const requireAuth = require("../../middleware/requireAuth.js");
const express = require("express");
const router = express.Router();
const xyte = require("../../xyte/xyteClient");
const { sendResponse } = require("../../utils/sendResponse.js");
const { STATUS_FLAG } = require("../../utils/constants.js");

/**
 * @swagger
 * /api/v1/devices/claim:
 *   post:
 *     summary: Claim a device via Xyte
 *     tags: [Devices]
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
 *               - space_id
 *               - cloud_id
 *             properties:
 *               name:
 *                 type: string
 *                 description: Friendly device name
 *                 example: Conference Room Display
 *               space_id:
 *                 type: integer
 *                 description: ID of the space where the device is assigned
 *                 example: 13244
 *               mac:
 *                 type: string
 *                 nullable: true
 *                 description: MAC address of the device (optional)
 *                 example: null
 *               sn:
 *                 type: string
 *                 nullable: true
 *                 description: Serial number of the device (optional)
 *                 example: null
 *               cloud_id:
 *                 type: string
 *                 description: Xyte Cloud ID for the device
 *                 example: "abc-xyz-123-cloud-id"
 *     responses:
 *       200:
 *         description: Device claimed successfully
 *       400:
 *         description: Invalid request body
 *       401:
 *         description: Unauthorized or missing token
 *       500:
 *         description: Error communicating with Xyte API
 */

router.post("/claim", requireAuth, async (req, res) => {
  try {
    // now req.user.sub contains userId
    const userId = req.user.sub;
    const response = await xyte.post("/devices/claim", req.body);
    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Device claimed successfully",
      response.data
    );
  } catch (err) {
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error claiming device",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/devices:
 *   get:
 *     summary: Get list of devices
 *     tags: [Devices]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of devices
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 type: object
 *                 properties:
 *                   deviceId:
 *                     type: string
 *                   status:
 *                     type: string
 */

router.get("/", requireAuth, async (req, res) => {
  try {
    // now req.user.sub contains userId
    const userId = req.user.sub;

    // Optional: use userId to track usage or store per-user metadata
    const response = await xyte.get("/devices");
    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Devices retrieved successfully",
      response.data
    );
  } catch (err) {
    console.error("Error fetching devices:", err.message);
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error fetching devices",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/devices/histories:
 *   get:
 *     summary: Retrieve device histories from Xyte
 *     tags: [Devices]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: status
 *         schema:
 *           type: string
 *           enum: [online, offline, unavailable, error]
 *         description: Filter by device status
 *       - in: query
 *         name: from
 *         schema:
 *           type: string
 *           format: date-time
 *         description: Start date for filtering (ISO format)
 *       - in: query
 *         name: to
 *         schema:
 *           type: string
 *           format: date-time
 *         description: End date for filtering (ISO format)
 *       - in: query
 *         name: device_id
 *         schema:
 *           type: string
 *         description: Filter by unique device ID
 *       - in: query
 *         name: space_id
 *         schema:
 *           type: integer
 *         description: Filter by space ID
 *       - in: query
 *         name: name
 *         schema:
 *           type: string
 *         description: Filter by device name
 *     responses:
 *       200:
 *         description: Paginated list of device histories
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 items:
 *                   type: array
 *                   items:
 *                     type: object
 *                     properties:
 *                       uuid:
 *                         type: string
 *                       created_at:
 *                         type: string
 *                         format: date-time
 *                       name:
 *                         type: string
 *                       space_id:
 *                         type: integer
 *                       model:
 *                         type: string
 *                       partner:
 *                         type: string
 *                       state:
 *                         type: object
 *       401:
 *         description: Unauthorized
 *       500:
 *         description: Server error
 */
router.get("/histories", requireAuth, async (req, res) => {
  try {
    // Forward query parameters directly to Xyte
    const response = await xyte.get("/devices/histories", {
      params: req.query,
    });

    // Send the response data back to the client
    sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Device histories retrieved successfully",
      response.data
    );
  } catch (err) {
    console.error("Error fetching device histories:", err.message);
    sendResponse(
      res,
      err.response?.status || 500,
      STATUS_FLAG.ERROR,
      "Error fetching device histories",
      err.message
    );
  }
});

module.exports = router;
