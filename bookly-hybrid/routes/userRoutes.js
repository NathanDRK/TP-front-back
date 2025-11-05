import { Router } from 'express';
import { listUsers, addUser, getUser, getUserFull, updateUser, removeUser } from '../controllers/userController.js';

const router = Router();
router.get('/', listUsers);          // GET /api/users
router.post('/', addUser);           // POST /api/users
router.get('/:id', getUser);         // GET /api/users/:id
router.get('/full/:id', getUserFull);// GET /api/users/full/:id  (alias lisible)
router.put('/:id', updateUser);      // PUT /api/users/:id
router.delete('/:id', removeUser);   // DELETE /api/users/:id
export default router;