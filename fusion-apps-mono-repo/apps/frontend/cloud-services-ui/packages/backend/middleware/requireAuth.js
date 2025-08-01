const jwt = require("jsonwebtoken");
const { sendResponse } = require("../utils/sendResponse");
const { STATUS_FLAG } = require("../utils/constants");

function requireAuth(req, res, next) {
  const authHeader = req.headers.authorization;

  if (!authHeader) {
    return sendResponse(
      res,
      401,
      STATUS_FLAG.ERROR,
      "Missing Authorization header"
    );
  }

  const token = authHeader.split(" ")[1];

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    return sendResponse(
      res,
      401,
      STATUS_FLAG.ERROR,
      "Invalid or expired token"
    );
  }
}

module.exports = requireAuth;
