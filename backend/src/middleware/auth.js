const jwt = require('jsonwebtoken');

const JWT_SECRET = process.env.JWT_SECRET || 'zyeta_workforce_gate_super_secret_jwt_key_2026';

const authenticateToken = (req, res, next) => {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: 'Access token required' });
  }

  jwt.verify(token, JWT_SECRET, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: 'Invalid or expired token' });
    }
    req.user = user;
    next();
  });
};

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ success: false, message: 'Authentication required' });
    }
    // Super Admin has universal access
    if (req.user.role === 'Super Admin') {
      return next();
    }
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Requires one of roles: ${roles.join(', ')}`
      });
    }
    next();
  };
};

module.exports = {
  JWT_SECRET,
  authenticateToken,
  authorizeRoles
};
