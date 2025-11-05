const Product = require("../models/product.model");

exports.listProducts = (req, res, next) => {
  try {
    const { q, minPrice, maxPrice, limit = 50, offset = 0 } = req.query;
    let data = Product.findAll();
    if (q)
      data = data.filter((p) =>
        p.name.toLowerCase().includes(String(q).toLowerCase())
      );
    if (minPrice !== undefined)
      data = data.filter((p) => p.price >= Number(minPrice));
    if (maxPrice !== undefined)
      data = data.filter((p) => p.price <= Number(maxPrice));
    const start = Number(offset);
    const end = start + Number(limit);
    return res.status(200).json({ total: data.length, data: data.slice(start, end) });
  } catch (e) {
    next(e);
  }
};

exports.getProduct = (req, res, next) => {
  try {
    const product = Product.findById(Number(req.params.id));
    if (!product) return res.status(404).json({ error: "Produit non trouvé" });
    return res.status(200).json(product);
  } catch (e) {
    next(e);
  }
};

exports.createProduct = (req, res, next) => {
  try {
    const { name, price } = req.body;
    if (name === undefined || price === undefined) {
      return res
        .status(400)
        .json({ error: "name (string) et price (number) sont requis" });
    }
    const created = Product.createOne({ name, price });
    return res.status(201).json(created);
  } catch (e) {
    next(e);
  }
};

exports.updateProduct = (req, res, next) => {
  try {
    const updated = Product.updateOne(Number(req.params.id), req.body);
    if (!updated) return res.status(404).json({ error: "Produit non trouvé" });
    return res.status(200).json(updated);
  } catch (e) {
    next(e);
  }
};

exports.deleteProduct = (req, res, next) => {
  try {
    const ok = Product.deleteOne(Number(req.params.id));
    if (!ok) return res.status(404).json({ error: "Produit non trouvé" });
    return res.status(204).send();
  } catch (e) {
    next(e);
  }
};


