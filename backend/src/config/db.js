const fs = require('fs');
const path = require('path');

const dataDir = path.join(__dirname, '../../data');
const dbFilePath = path.join(dataDir, 'database.json');

if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

let dbData = {
  users: [],
  roles: [],
  sites: [],
  departments: [],
  shifts: [],
  gates: [],
  vendors: [],
  employees: [],
  employee_documents: [],
  vendor_documents: [],
  gate_transactions: [],
  attendance: [],
  permits: [],
  materials: [],
  visitors: [],
  vehicles: [],
  notifications: [],
  audit_logs: []
};

const loadDatabase = () => {
  try {
    if (fs.existsSync(dbFilePath)) {
      const raw = fs.readFileSync(dbFilePath, 'utf8');
      dbData = { ...dbData, ...JSON.parse(raw) };
      console.log('Database loaded from disk.');
    } else {
      saveDatabase();
      console.log('New database created at', dbFilePath);
    }
  } catch (err) {
    console.error('Error loading database file:', err);
  }
};

const saveDatabase = () => {
  try {
    fs.writeFileSync(dbFilePath, JSON.stringify(dbData, null, 2), 'utf8');
  } catch (err) {
    console.error('Error writing database to disk:', err);
  }
};

// Generic Database Repository Factory
class Table {
  constructor(name) {
    this.name = name;
  }

  get items() {
    if (!dbData[this.name]) {
      dbData[this.name] = [];
    }
    return dbData[this.name];
  }

  find(predicate = () => true) {
    return this.items.filter(predicate);
  }

  findById(id) {
    return this.items.find((item) => Number(item.id) === Number(id)) || null;
  }

  findOne(predicate) {
    return this.items.find(predicate) || null;
  }

  create(record) {
    const nextId = this.items.reduce((max, r) => Math.max(max, Number(r.id) || 0), 0) + 1;
    const newRecord = {
      id: nextId,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
      ...record
    };
    this.items.push(newRecord);
    saveDatabase();
    return newRecord;
  }

  update(id, updates) {
    const index = this.items.findIndex((item) => Number(item.id) === Number(id));
    if (index === -1) return null;
    const updatedRecord = {
      ...this.items[index],
      ...updates,
      updated_at: new Date().toISOString()
    };
    this.items[index] = updatedRecord;
    saveDatabase();
    return updatedRecord;
  }

  delete(id) {
    const index = this.items.findIndex((item) => Number(item.id) === Number(id));
    if (index === -1) return false;
    this.items.splice(index, 1);
    saveDatabase();
    return true;
  }

  count(predicate = () => true) {
    return this.items.filter(predicate).length;
  }

  clear() {
    dbData[this.name] = [];
    saveDatabase();
  }
}

// Instantiate tables
const db = {
  users: new Table('users'),
  roles: new Table('roles'),
  sites: new Table('sites'),
  departments: new Table('departments'),
  shifts: new Table('shifts'),
  gates: new Table('gates'),
  vendors: new Table('vendors'),
  employees: new Table('employees'),
  employee_documents: new Table('employee_documents'),
  vendor_documents: new Table('vendor_documents'),
  gate_transactions: new Table('gate_transactions'),
  attendance: new Table('attendance'),
  permits: new Table('permits'),
  materials: new Table('materials'),
  visitors: new Table('visitors'),
  vehicles: new Table('vehicles'),
  notifications: new Table('notifications'),
  audit_logs: new Table('audit_logs'),
  loadDatabase,
  saveDatabase
};

// Initial load
loadDatabase();

module.exports = db;
