class User {
  #id;
  #name;
  #age;
  constructor({ id, name, age }) {
    this.#id = id;
    this.setName(name);
    this.setAge(age);
  }
  // ---------- Validation + Factory ----------
  static create({ id, name, age }) {
    if (typeof name !== "string" || !name.trim()) {
      throw new Error("Name must be a non-empty string");
    }
    if (typeof age !== "number" || age < 0) {
      throw new Error("Age must be a positive number");
    }
    return new User({ id, name: name.trim(), age });
  }
  // ---------- Encapsulation ----------
  get id() {
    return this.#id;
  }
  get name() {
    return this.#name;
  }
  get age() {
    return this.#age;
  }
  setName(name) {
    if (typeof name !== "string" || !name.trim())
      throw new Error("Invalid name");
    this.#name = name.trim();
  }
  setAge(age) {
    if (typeof age !== "number" || age < 0) throw new Error("Invalid age");
    this.#age = age;
  }
  toJSON() {
    return { id: this.#id, name: this.#name, age: this.#age };
  }
  // ---------- "Persistance" en mémoire ----------
  static #data = [
    User.create({ id: 1, name: "Alice", age: 25 }),
    User.create({ id: 2, name: "Bob", age: 30 }),
  ];
  static nextId() {
    return Date.now();
  }
  static findAll() {
    return this.#data.map((u) => u.toJSON());
  }
  static findById(id) {
    const u = this.#data.find((u) => u.id === id);
    return u ? u.toJSON() : null;
  }
  static createOne({ name, age }) {
    const user = User.create({ id: this.nextId(), name, age });
    this.#data.push(user);
    return user.toJSON();
  }
  static updateOne(id, dto) {
    const idx = this.#data.findIndex((u) => u.id === id);
    if (idx === -1) return null;
    // Mise à jour avec validation via setters
    if (dto.name !== undefined) this.#data[idx].setName(dto.name);
    if (dto.age !== undefined) this.#data[idx].setAge(dto.age);
    return this.#data[idx].toJSON();
  }
  static deleteOne(id) {
    const before = this.#data.length;
    this.#data = this.#data.filter((u) => u.id !== id);
    return this.#data.length !== before; // true si supprimé
  }
}
module.exports = User;
