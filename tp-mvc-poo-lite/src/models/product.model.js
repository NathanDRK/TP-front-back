class Product {
  #id;
  #name;
  #price;

  constructor({ id, name, price }) {
    this.#id = id;
    this.setName(name);
    this.setPrice(price);
  }

  // ---------- Factory + validation centrale ----------
  static create({ id, name, price }) {
    if (typeof name !== "string" || !name.trim()) {
      throw new Error("Name must be a non-empty string");
    }
    if (typeof price !== "number" || Number.isNaN(price) || price < 0) {
      throw new Error("Price must be a number >= 0");
    }
    return new Product({ id, name: name.trim(), price });
  }

  // ---------- Encapsulation ----------
  get id() {
    return this.#id;
  }
  get name() {
    return this.#name;
  }
  get price() {
    return this.#price;
  }
  setName(name) {
    if (typeof name !== "string" || !name.trim()) {
      throw new Error("Invalid name");
    }
    this.#name = name.trim();
  }
  setPrice(price) {
    if (typeof price !== "number" || Number.isNaN(price) || price < 0) {
      throw new Error("Invalid price");
    }
    this.#price = price;
  }
  toJSON() {
    return { id: this.#id, name: this.#name, price: this.#price }; 
  }

  // ---------- "Persistance" en mémoire ----------
  static #data = [
    Product.create({ id: 1, name: "soda", price: 999.99 }),
    Product.create({ id: 2, name: "clavier", price: 19.9 }),
    Product.create({ id: 3, name: "noam", price: 49.0 }),
  ];

  static nextId() {
    return Date.now();
  }

  static findAll() {
    return this.#data.map((p) => p.toJSON());
  }

  static findById(id) {
    const p = this.#data.find((p) => p.id === id);
    return p ? p.toJSON() : null;
  }

  static createOne({ name, price }) {
    const product = Product.create({ id: this.nextId(), name, price });
    this.#data.push(product);
    return product.toJSON();
  }

  static updateOne(id, dto) {
    const idx = this.#data.findIndex((p) => p.id === id);
    if (idx === -1) return null;
    if (dto.name !== undefined) this.#data[idx].setName(dto.name);
    if (dto.price !== undefined) this.#data[idx].setPrice(dto.price);
    return this.#data[idx].toJSON();
  }

  static deleteOne(id) {
    const before = this.#data.length;
    this.#data = this.#data.filter((p) => p.id !== id);
    return this.#data.length !== before;
  }
}

module.exports = Product;
