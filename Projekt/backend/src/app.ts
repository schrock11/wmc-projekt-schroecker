import express, { Request, Response } from 'express';
import cors from 'cors';
import db from './database';

const app = express();
const port = 3000;

app.use(cors());
app.use(express.json());

// ==========================================
// 1. USERS ENDPUNKTE
// ==========================================

app.post('/api/users', (req: Request, res: Response) => {
    const { username } = req.body;
    
    if (!username) {
        res.status(400).json({ error: 'Username wird benötigt.' });
        return;
    }

    db.run(`INSERT INTO Users (username) VALUES (?)`, [username], function(err) {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        res.status(201).json({ id: this.lastID, username });
    });
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
app.post('/api/login', (req: Request, res: Response) => {
    const { username } = req.body;

    if (!username) {
        res.status(400).json({ error: 'Username wird benötigt.' });
        return;
    }

    db.get(`SELECT id, username FROM Users WHERE username = ?`, [username], (err, row) => {
        if (err) {
            res.status(500).json({ error: err.message });
            return;
        }
        if (!row) {
            // 401 Unauthorized, wenn der Name nicht in der Datenbank steht
            res.status(401).json({ error: 'User nicht gefunden. Bitte erst registrieren.' });
            return;
        }
        
        // User gefunden -> Daten zurückgeben
        res.json(row);
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