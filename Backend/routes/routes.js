const express = require('express');
const router = express.Router();
const dataController = require('../controllers/dataController');
const vehicleRoutes = require('./vehicleRoutes');
const SaveController = require('../controllers/SaveController');
const { bulkUpdateRole } = require('../controllers/UpdateRoleController');
const { removeRoleStep } = require('../controllers/removeController');

// Use consistent naming for your rate card controllers
const rateCardController = require('../controllers/ratecardController');
const rateCardCalculateController = require('../controllers/rateCardCalculateController');
const rateCardGetController = require('../controllers/ratecardGetcontroller');

const { getSubmissionStatus } = require('../controllers/submissionController');
const { searchCostCenters } = require('../controllers/costCenterController');
const tableRateController = require("../controllers/tableRateController");
const tableSummaryController = require("../controllers/tableSummaryController");
const userAdminController = require('../controllers/userAdminController');
const costCenterListController = require('../controllers/costCenterListController');
const ratecardController = require('../controllers/rateCardControllerNew');
const fuelRateControllerg = require('../controllers/fuelRatecontroller');
// Existing routes
router.get('/costcenters', searchCostCenters);
router.get('/submission-status', getSubmissionStatus);
router.post('/add_item', SaveController.saveData);
router.get('/user/:uid', dataController.getUser);
router.post('/get-data', dataController.getDataByDateAndFilter);
router.put('/update-data', SaveController.updateItem);
router.use('/vehicles', vehicleRoutes);
router.put('/update-bulk-role', bulkUpdateRole);
router.put('/remove-role', removeRoleStep);

// Rate card calculation routes
router.post('/calculate', rateCardController.calculateRateCard);
router.get('/calculated', rateCardController.getCalculatedRateCards);
router.get('/calculated/:id/slabs', rateCardController.getCalculatedRateSlabs);
router.get('/base/latest', rateCardController.getLatestBaseRateCard);

// NEW: Add the rate card get routes
router.get('/calculated-cards', rateCardGetController.getCalculatedRateCards);
router.get('/calculated-cards/:id', rateCardGetController.getRateCardDetails);
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory', rateCardGetController.getRateSlabsByYomCategory);
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/organized', rateCardGetController.getOrganizedSlabs);
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/service-types', rateCardGetController.getServiceTypes);
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/service/:serviceType/categories', rateCardGetController.getCategoriesByServiceType);


// Get categories for a YOM category
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/categories', rateCardController.getCategories);

// Get service types for a YOM category
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/service-types', rateCardController.getServiceTypes);

// Get fuel types for a specific category and service type
router.get('/calculated-cards/:calculatedCardId/yom/:yomCategory/category/:categoryCode/service/:serviceType/fuel-types', rateCardController.getFuelTypes);

// Calculate rental
router.post("/calculate-rates", rateCardCalculateController.calculateRates);
router.post("/calculate-rates/table", tableRateController.calculateAndPersistForTable);
router.post("/table-summary", tableSummaryController.summarizeWithRows);

//add user
router.post(
  '/admin/user-with-costcenters',
  userAdminController.createUserWithCostCenters
);
router.get(
  '/admin/cost-centers',
  costCenterListController.getCostCentersList
);
router.post('/insatebaserate', ratecardController.upsertRateCard);
router.post('/calculate-all', fuelRateControllerg.calculateAllActiveRates);
module.exports = router;