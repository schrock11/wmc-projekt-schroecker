import sqlite3 from 'sqlite3';

const db = new sqlite3.Database('debtbuddy.sqlite', (err) => {
    if (err) {
        console.error('Fehler beim Öffnen der Datenbank:', err.message);
    } else {
        console.log('Erfolgreich mit der SQLite Datenbank verbunden.');
    }
});

db.serialize(() => {
    db.run(`
        CREATE TABLE IF NOT EXISTS Users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE
        )
    `);

    db.run(`
        CREATE TABLE IF NOT EXISTS Friendships (
            user_id INTEGER,
            friend_id INTEGER,
            FOREIGN KEY(user_id) REFERENCES Users(id),
            FOREIGN KEY(friend_id) REFERENCES Users(id),
            PRIMARY KEY (user_id, friend_id)
        )
    `);

    db.run(`
        CREATE TABLE IF NOT EXISTS Transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            payer_id INTEGER,
            debtor_id INTEGER,
            amount DECIMAL(10, 2) NOT NULL,
            description TEXT,
            timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
            is_settled BOOLEAN DEFAULT 0,
            FOREIGN KEY(payer_id) REFERENCES Users(id),
            FOREIGN KEY(debtor_id) REFERENCES Users(id)
        )
    `);
    
    console.log('Alle Datenbank-Tabellen wurden erfolgreich initialisiert.');
});

export default db;