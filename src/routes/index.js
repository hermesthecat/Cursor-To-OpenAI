const express = require('express');
const router = express.Router();
const path = require('path');
const v1Routes = require('./v1');
const cursorRoutes = require('./cursor');

router.get('/', (req, res) => {
    res.send('Hello World');
});

// Test API sayfası
router.get('/api-test', (req, res) => {
    res.sendFile(path.join(__dirname, '../web/test-api.html'));
});

// OpenAI v1 API routes
router.use('/v1', v1Routes);
router.use('/cursor', cursorRoutes);

module.exports = router;
