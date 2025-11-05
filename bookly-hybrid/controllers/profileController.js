import mongoose from 'mongoose';
import { Profile } from '../models/Profile.model.js';
import { getUserById } from '../models/User.model.js';

export async function getProfile(req, res) {
  try {
    const userId = Number(req.params.userId);
    const profile = await Profile.findOne({ userId }).lean();
    if (!profile) return res.status(404).json({ error: 'Profile not found' });
    res.json(profile);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function createProfile(req, res) {
  try {
    const { userId, preferences = [], history = [] } = req.body;
    if (typeof userId !== 'number') return res.status(400).json({ error: 'userId (number) required' });

    // s'assurer que l'utilisateur SQL existe
    const user = await getUserById(userId);
    if (!user) return res.status(400).json({ error: 'User does not exist in SQL' });

    const _id = new mongoose.Types.ObjectId();
    const created = await Profile.create({ _id, userId, preferences, history });
    res.status(201).json(created);
  } catch (e) {
    if (e.code === 11000) return res.status(409).json({ error: 'Profile already exists' });
    res.status(500).json({ error: e.message });
  }
}

export async function updateProfile(req, res) {
  try {
    const userId = Number(req.params.userId);
    const { preferences, historyEntry } = req.body;

    const update = {};
    if (Array.isArray(preferences)) update.$set = { preferences };
    if (historyEntry) update.$push = { history: historyEntry };

    const result = await Profile.findOneAndUpdate({ userId }, update, { new: true }).lean();
    if (!result) return res.status(404).json({ error: 'Profile not found' });
    res.json(result);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}