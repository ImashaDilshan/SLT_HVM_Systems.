const dataModel = require("../models/SaveModel");
const upModel = require("../models/UpdateModel");

// Utility to map frontend fields to DB format
async function mapFormDataToDbFields(data, supplier) {
  const dbFieldsMap = {
    user: "subUser",
    ref_no: "refNo",
    type: "type",
    from_date: "fromDate",
    to_date: "toDate",
    km_run: "kmRun",
    ot_hrs: "otHours",
    overnight: "overnight",
    rental: null,
    supplier: "supplier",
    branding: "branding",
    tracking: "tracking",
    brandingOther: "brandingOther",
    trackingOther: "trackingOther",
    cost_center: null,
    vehicle_no: null,
    vehicle_type: null,
    category: null,
    manufacture_year: null,
    dgm: null,
    gm: null,
    District: null,
    fuel_type: null,
    working_days: null,
    accept_role: "role",
    overnight_amount: null,
    excess_km: null,
    excess_amount: null,
    absent_total: null,
    absent_deduct_amount: null,
    total: null,
    tax_18_percent: null,
    grand_total: null,
    rate_category: "rateCategory",
    rate_period: "ratePeriod",
  };

  const rows = Array.isArray(data) ? data : [data];
  const result = [];

  for (const row of rows) {
    const formatted = {};
    for (const dbKey in dbFieldsMap) {
      const inputKey = dbFieldsMap[dbKey];
      formatted[dbKey] = inputKey ? row[inputKey] || null : null;
    }

    const refNo = row["refNo"] || row["ref_no"];
    if (refNo) {
      const extraDetails = await dataModel.getDetailsByRefNo(refNo);
      if (extraDetails) {
        formatted.cost_center = extraDetails.cost_center || null;
        formatted.vehicle_no = extraDetails.vehicle_no || null;
        formatted.vehicle_type = extraDetails.vehicle_type || null;
        formatted.category = extraDetails.category || null;
        formatted.manufacture_year = extraDetails.manuf_year || null;
        formatted.dgm = extraDetails.dgm || null;
        formatted.gm = extraDetails.gm || null;
        formatted.fuel_type = extraDetails.fuel_type || null;
        formatted.District = extraDetails.District || null;
        
      }
    }

    formatted.supplier = supplier || null;
    result.push(formatted);
  }

  return Array.isArray(data) ? result : result[0];
}

async function saveData(req, res) {
  const { tableName, supplier, data } = req.body;

  try {
    const exists = await dataModel.checkTableExists(tableName);
    if (!exists) await dataModel.createTable(tableName);

    const formattedData = await mapFormDataToDbFields(data, supplier);
    await dataModel.insertData(tableName, formattedData);

    res.json({ success: true, message: "Data saved successfully" });
  } catch (err) {
    console.error("❌ Save Error:", err);
    if (err.code === "ER_DUP_ENTRY") {
      res.status(409).json({
        success: false,
        message: `Duplicate entry: '${data.refNo}' already exists.`,
      });
    } else if (err.code === "ER_NO_SUCH_TABLE") {
      res.status(400).json({
        success: false,
        message: `Table '${tableName}' does not exist.`,
      });
    } else {
      res.status(500).json({
        success: false,
        message: "Failed to save data",
      });
    }
  }
}

async function updateItem(req, res) {
  try {
    const { tableName, refNo, ...data } = req.body;

    const exists = await upModel.checkTableExists(tableName);
    if (!exists) {
      return res.status(404).json({ success: false, message: 'Table not found' });
    }

    const validFields = {
      user: data.subUser,
      type: data.type,
      from_date: data.fromDate,
      to_date: data.toDate,
      km_run: data.kmRun,
      ot_hrs: data.otHours,
      overnight: data.overnight,
      accept_role: data.role,
      supplier: data.supplier
    };

    const result = await upModel.updateByRefNo(tableName, refNo, validFields);

    if (result.affectedRows === 0) {
      return res.status(404).json({ success: false, message: 'Record not found' });
    }

    res.json({ success: true, message: 'Data updated successfully' });

  } catch (err) {
    console.error("❌ Update Error:", err);
    res.status(500).json({ success: false, message: 'Failed to update data' });
  }

}

module.exports = {
  saveData,
  updateItem,
};
