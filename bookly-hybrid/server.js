import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import { pool } from './config/db.postgres.js';
import { connectMongo } from './config/db.mongo.js';

import userRoutes from './routes/userRoutes.js';
import bookRoutes from './routes/bookRoutes.js';
import profileRoutes from './routes/profileRoutes.js';

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

// test ping Postgres au démarrage
pool.query('SELECT 1').then(() => console.log('✅ PostgreSQL connected'))
  .catch(err => { console.error('Postgres connection error:', err.message); process.exit(1); });

// connexion Mongo
await connectMongo();

// routes
app.use('/api/users', userRoutes);
app.use('/api/books', bookRoutes);
app.use('/api/profiles', profileRoutes);

// route mixte canonique du TP
app.get('/api/user-full/:id', async (req, res, next) => {
  // on peut déléguer à getUserFull si tu préfères garder tout en controllers
  next();
});

const PORT = process.env.PORT || 4000;
app.listen(PORT, () => console.log(`🚀 API running on http://localhost:${PORT}`));