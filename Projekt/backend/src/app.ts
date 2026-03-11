import express, { Request, Response } from 'express';
import cors from 'cors';
import bcrypt from 'bcryptjs';
import db from './database';

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

const SALT_ROUNDS = 10;

// ==========================================
// 1. USERS ENDPUNKTE
// ==========================================

app.post('/api/users', async (req: Request, res: Response) => {
    const { username, password } = req.body;
    
    if (!username || !password) {
        res.status(400).json({ error: 'Username und Passwort werden benötigt.' });
        return;
    }

    if (String(password).length < 6) {
        res.status(400).json({ error: 'Das Passwort muss mindestens 6 Zeichen haben.' });
        return;
    }

    try {
        const passwordHash = await bcrypt.hash(String(password), SALT_ROUNDS);

        db.get(
            `SELECT id, password_hash FROM Users WHERE username = ?`,
            [username],
            (lookupErr, existingUser: { id: number; password_hash: string | null } | undefined) => {
                if (lookupErr) {
                    res.status(500).json({ error: lookupErr.message });
                    return;
                }

                // Legacy-User ohne Passwort können durch erneutes Register auf Passwort-Login migriert werden.
                if (existingUser) {
                    if (existingUser.password_hash) {
                        res.status(409).json({ error: 'Username ist bereits vergeben.' });
                        return;
                    }

                    db.run(
                        `UPDATE Users SET password_hash = ? WHERE id = ?`,
                        [passwordHash, existingUser.id],
                        function(updateErr) {
                            if (updateErr) {
                                res.status(500).json({ error: updateErr.message });
                                return;
                            }
                            res.status(200).json({ id: existingUser.id, username });
                        }
                    );
                    return;
                }

                db.run(
                    `INSERT INTO Users (username, password_hash) VALUES (?, ?)`,
                    [username, passwordHash],
                    function(insertErr) {
                        if (insertErr) {
                            res.status(500).json({ error: insertErr.message });
                            return;
                        }
                        res.status(201).json({ id: this.lastID, username });
                    }
                );
            }
        );
    } catch (error) {
        res.status(500).json({ error: 'Passwort konnte nicht verarbeitet werden.' });
    }
});

app.get('/api/users/:id', (req: Request, res: Response) => {
    const userId = req.params.id;
    db.get(`SELECT id, username FROM Users WHERE id = ?`, [userId], (err, row) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        if (!row) {
            res.status(404).json({ error: 'User nicht gefunden.' });
            return;
        }
        res.json(row);
    });
});

// ==========================================
// LOGIN ENDPUNKT
// ==========================================
app.post('/api/login', async (req: Request, res: Response) => {
    const { username, password } = req.body;

    if (!username || !password) {
        res.status(400).json({ error: 'Username und Passwort werden benötigt.' });
        return;
    }

    db.get(
        `SELECT id, username, password_hash FROM Users WHERE username = ?`,
        [username],
        async (err, row: { id: number; username: string; password_hash: string | null } | undefined) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        if (!row) {
            res.status(401).json({ error: 'Ungültige Zugangsdaten.' });
            return;
        }

        const passwordHash = row.password_hash ?? '';
        const isPasswordValid = await bcrypt.compare(String(password), passwordHash);

        if (!isPasswordValid) {
            res.status(401).json({ error: 'Ungültige Zugangsdaten.' });
            return;
        }

        res.json({ id: row.id, username: row.username });
    });
});


// ==========================================
// 2. FRIENDSHIPS ENDPUNKTE
// ==========================================

app.post('/api/friendships', (req: Request, res: Response) => {
    const { user_id, friend_id } = req.body;

    if (!user_id || !friend_id) {
        res.status(400).json({ error: 'user_id und friend_id werden benötigt.' });
        return;
    }

    db.run(
        `INSERT INTO Friendships (user_id, friend_id) VALUES (?, ?)`, 
        [user_id, friend_id], 
        function(err) {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            res.status(201).json({ message: 'Freund erfolgreich hinzugefügt!' });
        }
    );
});

app.get('/api/users/:id/friends', (req: Request, res: Response) => {
    const userId = req.params.id;
    const query = `
        SELECT u.id, u.username 
        FROM Users u
        JOIN Friendships f ON u.id = f.friend_id
        WHERE f.user_id = ?
    `;

    db.all(query, [userId], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});


// ==========================================
// 3. TRANSACTIONS ENDPUNKTE
// ==========================================

app.post('/api/transactions', (req: Request, res: Response) => {
    const { payer_id, debtor_id, amount, description } = req.body;

    if (!payer_id || !debtor_id || !amount) {
        res.status(400).json({ error: 'payer_id, debtor_id und amount sind Pflichtfelder.' });
        return;
    }

    const query = `INSERT INTO Transactions (payer_id, debtor_id, amount, description) VALUES (?, ?, ?, ?)`;
    
    db.run(query, [payer_id, debtor_id, amount, description], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.status(201).json({ 
            id: this.lastID, 
            message: 'Transaktion erfolgreich gespeichert.' 
        });
    });
});

app.get('/api/users/:id/transactions', (req: Request, res: Response) => {
    const userId = req.params.id;
    const query = `
        SELECT * FROM Transactions 
        WHERE payer_id = ? OR debtor_id = ?
        ORDER BY timestamp DESC
    `;

    db.all(query, [userId, userId], (err, rows) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.json(rows);
    });
});

app.patch('/api/transactions/:id/settle', (req: Request, res: Response) => {
    const transactionId = req.params.id;

    db.run(
        `UPDATE Transactions SET is_settled = 1 WHERE id = ?`, 
        [transactionId], 
        function(err) {
            if (err) {
                res.status(500).json({ error: err.message });
                return;
            }
            if (this.changes === 0) {
                res.status(404).json({ error: 'Transaktion nicht gefunden.' });
                return;
            }
            
            res.json({ message: 'Schuld erfolgreich beglichen (settled).' });
        }
    );
});

// ==========================================
// SERVER STARTEN
// ==========================================
app.listen(port, () => {
    console.log(`DebtBuddy Backend läuft auf http://localhost:${port}`);
});