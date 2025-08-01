export const sendResponse = (
  res,
  statusCode = null,
  statusMessage = "",
  message = "",
  data = {}
) => {
  return res.status(statusCode).json({ status: statusMessage, message, data });
};
