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
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL
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

    // Migriert bestehende Datenbanken, die noch keine Passwort-Spalte besitzen.
    db.all(`PRAGMA table_info(Users)`, (err, columns: Array<{ name: string }>) => {
        if (err) {
            console.error('Fehler beim Lesen der Users-Tabellenstruktur:', err.message);
            return;
        }

        const hasPasswordHash = columns.some((column) => column.name === 'password_hash');
        if (!hasPasswordHash) {
            db.run(`ALTER TABLE Users ADD COLUMN password_hash TEXT`, (alterErr) => {
                if (alterErr) {
                    console.error('Fehler bei der Migration von Users.password_hash:', alterErr.message);
                    return;
                }
                console.log('Migration abgeschlossen: Users.password_hash wurde hinzugefügt.');
            });
        }
    });
    
    console.log('Alle Datenbank-Tabellen wurden erfolgreich initialisiert.');
});

export default db;