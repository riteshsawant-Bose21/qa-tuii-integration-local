const express = require("express");
const bcrypt = require("bcryptjs");
const jwt = require("jsonwebtoken");
const db = require("../../db");
const router = express.Router();
const requireAuth = require("../../middleware/requireAuth.js");
const { sendResponse } = require("../../utils/sendResponse.js");
const { STATUS_FLAG } = require("../../utils/constants.js");

/**
 * @swagger
 * tags:
 *   name: Auth
 *   description: User authentication (register and login)
 */

/**
 * @swagger
 * /api/v1/auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - password
 *             properties:
 *               userId:
 *                 type: string
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 example: SuperSecret123
 *     responses:
 *       201:
 *         description: User registered and authenticated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                       example: user@example.com
 *                     metadata:
 *                       type: object
 *                       example: {}
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                       example: 2024-01-01T00:00:00Z
 *       400:
 *         description: Missing or invalid userId or password
 *       409:
 *         description: User already exists
 */

router.post("/register", async (req, res) => {
  const { email, password } = req.body;
  const hash = bcrypt.hashSync(password, 10);

  if (!email || !password) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing email or password",
      {}
    );
  }

  // Check email format
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  if (!emailRegex.test(email)) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Invalid email format",
      {}
    );
  }

  db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, userRow) => {
    if (userRow) {
      return sendResponse(
        res,
        409,
        STATUS_FLAG.ERROR,
        "User already exists",
        {}
      );
    }
    db.run(
      `INSERT INTO users (email, passwordHash, createdAt, metadata) VALUES (?, ?, datetime('now'), '{}')`,
      [email, hash],
      function (err) {
        if (err) {
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Failed to register user",
            {}
          );
        }
        const user = {
          id: this.lastID,
          email,
          metadata: {},
        };
  
        sendResponse(
          res,
          201,
          STATUS_FLAG.SUCCESS,
          "User registered successfully",
          user
        );
      }
    );
  });
});

/**
 * @swagger
 * /api/v1/auth/login:
 *   post:
 *     summary: Log in an existing user
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - password
 *             properties:
 *               userId:
 *                 type: string
 *                 example: user@example.com
 *               password:
 *                 type: string
 *                 example: SuperSecret123
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 accessToken:
 *                   type: string
 *                 refreshToken:
 *                   type: string
 *                 expiresIn:
 *                   type: integer
 *                   example: 3600
 *                 user:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                       example: user@example.com
 *                     metadata:
 *                       type: object
 *                       example: {}
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                       example: 2024-01-01T00:00:00Z
 *       400:
 *         description: Missing or invalid userId or password
 *       401:
 *         description: Invalid credentials
 */
router.post("/login", (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing email or password",
      {}
    );
  }

  db.get(`SELECT * FROM users WHERE email = ?`, [email], (err, userRow) => {
    if (!userRow || !bcrypt.compareSync(password, userRow.passwordHash)) {
      return sendResponse(
        res,
        401,
        STATUS_FLAG.ERROR,
        "Invalid credentials",
        {}
      );
    }

    const expiresIn = 3600; // 1 hour
    const refreshExpiresIn = 30 * 24 * 3600; // 30 days

    const accessToken = jwt.sign({ sub: userRow.id }, process.env.JWT_SECRET, {
      expiresIn,
    });
    const refreshToken = jwt.sign(
      { sub: userRow.id },
      process.env.JWT_REFRESH_SECRET,
      { expiresIn: refreshExpiresIn }
    );

    const user = {
      id: userRow.id,
      email: userRow.email,
      metadata: JSON.parse(userRow.metadata || "{}"),
    };

    sendResponse(res, 200, STATUS_FLAG.SUCCESS, "Login successful", {
      accessToken,
      refreshToken,
      expiresIn,
      user,
    });
  });
});

/**
 * @swagger
 * /api/v1/auth/refresh:
 *   post:
 *     summary: Refresh the access token using a refresh token
 *     tags: [Auth]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - refreshToken
 *             properties:
 *               refreshToken:
 *                 type: string
 *                 example: your-refresh-token-here
 *     responses:
 *       200:
 *         description: New access token issued successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 accessToken:
 *                   type: string
 *                   description: New access token
 *                 expiresIn:
 *                   type: integer
 *                   example: 3600
 *       400:
 *         description: Missing refresh token
 *       403:
 *         description: Invalid or expired refresh token
 */
router.post("/refresh", (req, res) => {
  const refreshToken = req.body?.refreshToken;

  if (!refreshToken) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Missing refresh token",
      {}
    );
  }

  try {
    const payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    const userId = payload.sub;

    // Issue a new short-lived access token
    const expiresIn = 3600; // 1 hour
    const accessToken = jwt.sign({ sub: userId }, process.env.JWT_SECRET, {
      expiresIn,
    });

    return sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "New access token issued successfully",
      { accessToken, expiresIn }
    );
  } catch (err) {
    console.error("Error refreshing token:", err);
    return sendResponse(
      res,
      403,
      STATUS_FLAG.ERROR,
      "Invalid or expired refresh token",
      {}
    );
  }
});

/**
 * @swagger
 * /api/v1/auth/me:
 *   get:
 *     summary: Get the current authenticated user's details
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Authenticated user retrieved successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                       example: user@example.com
 *                     metadata:
 *                       type: object
 *                       example: {}
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                       example: 2024-01-01T00:00:00Z
 *       401:
 *         description: Unauthorized or invalid token
 *       404:
 *         description: User not found
 */
router.get("/me", requireAuth, (req, res) => {
  const userId = req.user.sub;

  db.get(`SELECT * FROM users WHERE id = ?`, [userId], (err, userRow) => {
    if (err || !userRow) {
      return sendResponse(res, 404, STATUS_FLAG.ERROR, "User not found", {});
    }

    const user = {
      id: userRow.id,
      email: userRow.email,
      metadata: JSON.parse(userRow.metadata || "{}"),
    };

    return sendResponse(
      res,
      200,
      STATUS_FLAG.SUCCESS,
      "Authenticated user retrieved successfully",
      { user }
    );
  });
});

/**
 * @swagger
 * /api/v1/auth/metadata:
 *   post:
 *     summary: Update user metadata and return new authentication response
 *     tags: [Auth]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       description: Fields to update in the user's metadata
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             additionalProperties: true
 *             example:
 *               xyteApiKey: abc-123
 *               plan: pro
 *     responses:
 *       200:
 *         description: Metadata updated and new token issued
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 user:
 *                   type: object
 *                   properties:
 *                     userId:
 *                       type: string
 *                       example: user@example.com
 *                     metadata:
 *                       type: object
 *                       example:
 *                         xyteApiKey: abc-123
 *                         plan: pro
 *                     createdAt:
 *                       type: string
 *                       format: date-time
 *                       example: 2024-01-01T00:00:00Z
 *       400:
 *         description: Invalid input format
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: User not found
 *       500:
 *         description: Server error
 */

router.post("/metadata", requireAuth, (req, res) => {
  const userId = req.user.sub;
  const updates = req.body;

  if (!updates || typeof updates !== "object" || Array.isArray(updates)) {
    return sendResponse(
      res,
      400,
      STATUS_FLAG.ERROR,
      "Request body must be a valid JSON object",
      {}
    );
  }

  db.get(`SELECT * FROM users WHERE id = ?`, [userId], (err, userRow) => {
    if (err || !userRow) {
      return sendResponse(res, 404, STATUS_FLAG.ERROR, "User not found", {});
    }

    const existingMetadata = JSON.parse(userRow.metadata || "{}");
    const updatedMetadata = { ...existingMetadata, ...updates };

    db.run(
      `UPDATE users SET metadata = ? WHERE id = ?`,
      [JSON.stringify(updatedMetadata), userId],
      function (updateErr) {
        if (updateErr) {
          return sendResponse(
            res,
            500,
            STATUS_FLAG.ERROR,
            "Failed to update metadata",
            {}
          );
        }

        const user = {
          id: userRow.id,
          email: userRow.email,
          metadata: updatedMetadata,
        };

        return sendResponse(
          res,
          200,
          STATUS_FLAG.SUCCESS,
          "Metadata updated successfully",
          { user }
        );
      }
    );
  });
});

module.exports = router;
