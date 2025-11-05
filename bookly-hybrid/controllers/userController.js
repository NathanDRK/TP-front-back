import { getUsers, createUser, getUserById, updateUser as updateUserModel, deleteUser as deleteUserModel } from '../models/User.model.js';
import { Profile } from '../models/Profile.model.js';

export async function listUsers(req, res) {
  try {
    const users = await getUsers();
    res.json(users);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function addUser(req, res) {
  try {
    const { name, email } = req.body;
    if (!name || !email) return res.status(400).json({ error: 'name & email required' });
    const user = await createUser({ name, email });
    res.status(201).json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function getUser(req, res) {
  try {
    const user = await getUserById(Number(req.params.id));
    if (!user) return res.status(404).json({ error: 'User not found' });
    res.json(user);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
export async function getUserFull(req, res) {
  try {
    const id = Number(req.params.id);
    const user = await getUserById(id);
    if (!user) return res.status(404).json({ error: 'User not found' });
    const profile = await Profile.findOne({ userId: id }).lean();
    res.json({ user, profile: profile || null });
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function updateUser(req, res) {
  try {
    const id = Number(req.params.id);
    const { name, email } = req.body;
    if (!name || !email) return res.status(400).json({ error: 'name & email required' });
    const existing = await getUserById(id);
    if (!existing) return res.status(404).json({ error: 'User not found' });
    const updated = await updateUserModel({ id, name, email });
    res.json(updated);
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}

export async function removeUser(req, res) {
  try {
    const id = Number(req.params.id);
    const existing = await getUserById(id);
    if (!existing) return res.status(404).json({ error: 'User not found' });
    await deleteUserModel(id);
    res.status(204).send();
  } catch (e) {
    res.status(500).json({ error: e.message });
  }
}
  
