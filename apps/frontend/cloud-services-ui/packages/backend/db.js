const sqlite3 = require('sqlite3').verbose();
const db = new sqlite3.Database('./users.db');

db.serialize(() => {
  db.run(`CREATE TABLE IF NOT EXISTS users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    email TEXT UNIQUE,
    passwordHash TEXT,
    createdAt TEXT,
    metadata TEXT
  )`);
  db.run(`CREATE TABLE IF NOT EXISTS projects (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    userId TEXT,
    name TEXT,
    createdAt TEXT,
    updatedAt TEXT,
    metadata TEXT,
    FOREIGN KEY (userId) REFERENCES users(id)
  )`);
});

module.exports = db;
