const multer = require('multer');
const path = require('path');
const fs = require('fs');

const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadsDir);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname);
    const base = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '_');
    const uniqueSuffix = Date.now() + '_' + Math.round(Math.random() * 1e4);
    cb(null, `${base}_${uniqueSuffix}${ext}`);
  }
});

const upload = multer({
  storage: storage,
  limits: { fileSize: 15 * 1024 * 1024 } // 15MB limit
});

const handleFileUpload = (req, res) => {
  try {
    if (req.file) {
      const fileUrl = `/uploads/${req.file.filename}`;
      return res.json({
        success: true,
        message: 'File uploaded successfully',
        data: {
          filename: req.file.filename,
          original_name: req.file.originalname,
          size: req.file.size,
          mimetype: req.file.mimetype,
          url: fileUrl
        }
      });
    }

    // Handle base64 payload if provided as JSON
    if (req.body && req.body.base64_data) {
      const { base64_data, filename } = req.body;
      const matches = base64_data.match(/^data:([A-Za-z-+\/]+);base64,(.+)$/);
      let buffer;
      let finalName = filename || `upload_${Date.now()}.png`;

      if (matches && matches.length === 3) {
        buffer = Buffer.from(matches[2], 'base64');
      } else {
        buffer = Buffer.from(base64_data, 'base64');
      }

      const safeFilename = `${Date.now()}_${finalName.replace(/[^a-zA-Z0-9_.-]/g, '_')}`;
      const filePath = path.join(uploadsDir, safeFilename);
      fs.writeFileSync(filePath, buffer);

      return res.json({
        success: true,
        message: 'File uploaded successfully',
        data: {
          filename: safeFilename,
          original_name: finalName,
          size: buffer.length,
          url: `/uploads/${safeFilename}`
        }
      });
    }

    return res.status(400).json({ success: false, message: 'No file or base64 data provided' });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({ success: false, message: error.message });
  }
};

module.exports = {
  uploadMiddleware: upload.single('file'),
  handleFileUpload
};
