import mongoose from 'mongoose';

const historyEntrySchema = new mongoose.Schema({
  book: { type: String, required: true },
  rating: { type: Number, min: 0, max: 5 },
  comment: String,
  date: { type: Date, default: Date.now }
}, { _id: false });

const profileSchema = new mongoose.Schema({
  _id: { type: mongoose.Schema.Types.ObjectId, required: true },  // lié à l'utilisateur SQL via bridge applicatif
  userId: { type: Number, required: true, unique: true },         // id SQL de users
  preferences: [{ type: String }],
  history: [historyEntrySchema]
}, { collection: 'profiles', timestamps: true });

export const Profile = mongoose.model('Profile', profileSchema);