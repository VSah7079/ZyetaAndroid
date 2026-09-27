const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const db = require('../config/db');
const { JWT_SECRET } = require('../middleware/auth');
const { logAudit } = require('../middleware/audit');

const login = async (req, res) => {
  try {
    const { username, password } = req.body;
    if (!username || !password) {
      return res.status(400).json({ success: false, message: 'Username and password are required' });
    }

    const user = db.users.findOne((u) => u.username.toLowerCase() === username.toLowerCase() || u.email.toLowerCase() === username.toLowerCase());

    if (!user) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    if (user.status !== 'Active') {
      return res.status(403).json({ success: false, message: 'Account is deactivated or suspended' });
    }

    const isMatch = bcrypt.compareSync(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Invalid credentials' });
    }

    const payload = {
      id: user.id,
      username: user.username,
      email: user.email,
      role: user.role,
      vendor_id: user.vendor_id || null,
      full_name: user.full_name,
      site_id: user.site_id || 1
    };

    const token = jwt.sign(payload, JWT_SECRET, { expiresIn: '24h' });

    logAudit({
      userId: user.id,
      userName: user.full_name,
      userRole: user.role,
      actionType: 'LOGIN',
      module: 'Auth',
      affectedRecordId: user.id,
      details: `User ${user.username} logged in successfully`,
      ipAddress: req.ip
    });

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user: payload
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ success: false, message: 'Server error during login' });
  }
};

const getMe = async (req, res) => {
  try {
    const user = db.users.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    const { password_hash, ...safeUser } = user;
    res.json({ success: true, user: safeUser });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getUsers = async (req, res) => {
  try {
    const users = db.users.find().map(({ password_hash, ...safe }) => safe);
    res.json({ success: true, data: users });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const createUser = async (req, res) => {
  try {
    const { username, email, password, role, full_name, phone, vendor_id, site_id } = req.body;
    if (!username || !email || !password || !role || !full_name) {
      return res.status(400).json({ success: false, message: 'Missing required user fields' });
    }

    const existing = db.users.findOne((u) => u.username.toLowerCase() === username.toLowerCase() || u.email.toLowerCase() === email.toLowerCase());
    if (existing) {
      return res.status(400).json({ success: false, message: 'Username or email already exists' });
    }

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(password, salt);

    const newUser = db.users.create({
      username,
      email,
      password_hash,
      role,
      full_name,
      phone: phone || '',
      vendor_id: vendor_id || null,
      site_id: site_id || 1,
      status: 'Active'
    });

    logAudit({
      userId: req.user.id,
      userName: req.user.full_name,
      userRole: req.user.role,
      actionType: 'CREATE',
      module: 'Users',
      affectedRecordId: newUser.id,
      details: `Created new user account ${newUser.username} (${newUser.role})`,
      ipAddress: req.ip
    });

    const { password_hash: _, ...safeUser } = newUser;
    res.status(201).json({ success: true, user: safeUser });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

const getRoles = async (req, res) => {
  try {
    const roles = db.roles.find();
    res.json({ success: true, data: roles });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  login,
  getMe,
  getUsers,
  createUser,
  getRoles
};
