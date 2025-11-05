import { Router } from 'express';
import { listBooks, addBook } from '../controllers/bookController.js';
const router = Router();
router.get('/', listBooks);          // GET /api/books
router.post('/', addBook);           // POST /api/books
export default router;