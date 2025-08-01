const express = require("express");
const router = express.Router();
const requireAuth = require("../../middleware/requireAuth");
const multer = require("multer");
const path = require("path");
const fs = require("fs");
const { sendResponse } = require("../../utils/sendResponse");
const { STATUS_FLAG } = require("../../utils/constants");

// Configure multer - Will be S3 Later on!
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, path.join(__dirname, "../../uploads")); // Only storing locally.
  },
  filename: (req, file, cb) => {
    cb(null, Date.now() + "-" + file.originalname); // avoid conflicts
  },
});
const upload = multer({ storage });
/**
 * @swagger
 * /api/v1/files:
 *   post:
 *     summary: Upload a file
 *     tags: [Files]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         multipart/form-data:
 *           schema:
 *             type: object
 *             properties:
 *               file:
 *                 type: string
 *                 format: binary
 *     responses:
 *       201:
 *         description: File uploaded successfully
 *       400:
 *         description: No file uploaded
 *       401:
 *         description: Unauthorized
 */

// POST /files — Upload file
router.post("/", requireAuth, upload.single("file"), async (req, res) => {
  try {
    if (!req.file) {
      return sendResponse(res, 400, STATUS_FLAG.ERROR, "No file uploaded");
    }

    // potential file db for extra file info - maybe layer
    sendResponse(res, 201, STATUS_FLAG.SUCCESS, "File uploaded successfully", {
      filename: req.file.filename,
      path: `/uploads/${req.file.filename}`,
    });
  } catch (err) {
    console.error("Upload error:", err.message);
    sendResponse(
      res,
      500,
      STATUS_FLAG.ERROR,
      "Error uploading file",
      err.message
    );
  }
});

/**
 * @swagger
 * /api/v1/files/{filename}:
 *   get:
 *     summary: Download a file
 *     tags: [Files]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: filename
 *         schema:
 *           type: string
 *         required: true
 *         description: Name of the file to download
 *     responses:
 *       200:
 *         description: File downloaded successfully
 *       404:
 *         description: File not found
 *       401:
 *         description: Unauthorized
 */

// GET /files/:filename — Serve file
router.get("/:filename", requireAuth, (req, res) => {
  const filePath = path.join(__dirname, "../../uploads", req.params.filename);

  fs.access(filePath, fs.constants.F_OK, (err) => {
    if (err) {
      return sendResponse(
        res,
        404,
        STATUS_FLAG.ERROR,
        "File not found",
        err.message
      );
    }
    res.sendFile(filePath);
  });
});

module.exports = router;
