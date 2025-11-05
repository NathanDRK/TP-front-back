const User = require("../models/user.model");
exports.listUsers = (req, res, next) => {
  try {
    const { q, minAge, maxAge, limit = 50, offset = 0 } = req.query;
    let data = User.findAll();
    // Petits filtres côté controller (démo simple)
    if (q)
      data = data.filter((u) =>
        u.name.toLowerCase().includes(String(q).toLowerCase())
      );
    if (minAge) data = data.filter((u) => u.age >= Number(minAge));
    if (maxAge) data = data.filter((u) => u.age <= Number(maxAge));
    const start = Number(offset),
      end = start + Number(limit);
    return res
      .status(200)
      .json({ total: data.length, data: data.slice(start, end) });
  } catch (e) {
    next(e);
  }
};
exports.getUser = (req, res, next) => {
  try {
    const user = User.findById(Number(req.params.id));
    if (!user) return res.status(404).json({ error: "Utilisateur non trouvé" });
    return res.status(200).json(user);
  } catch (e) {
    next(e);
  }
};
exports.createUser = (req, res, next) => {
  try {
    const { name, age } = req.body;
    if (name === undefined || age === undefined) {
      return res
        .status(400)
        .json({ error: "name (string) et age (number) sont requis" });
    }
    const created = User.createOne({ name, age });
    return res.status(201).json(created);
  } catch (e) {
    next(e);
  }
};
exports.updateUser = (req, res, next) => {
  try {
    const updated = User.updateOne(Number(req.params.id), req.body);
    if (!updated)
      return res.status(404).json({ error: "Utilisateur non trouvé" });
    return res.status(200).json(updated);
  } catch (e) {
    next(e);
  }
};
exports.deleteUser = (req, res, next) => {
  try {
    const ok = User.deleteOne(Number(req.params.id));
    if (!ok) return res.status(404).json({ error: "Utilisateur non trouvé" });
    return res.status(204).send();
  } catch (e) {
    next(e);
  }
};
