const { getSubmissionRole } = require('../models/submissionModel');

async function getSubmissionStatus(req, res) {
  const { costCenterId, month, mode } = req.query;

  try {
    console.log(costCenterId, month, mode,"blbl");
    
    const role = await getSubmissionRole(costCenterId, month, mode);
    res.json({ role });
  } catch (err) {
    console.error(err.message);
    res.status(400).json({ error: err.message || 'Failed to check status' });
  }
}

module.exports = {
  getSubmissionStatus,
};