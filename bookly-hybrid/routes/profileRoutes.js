import { Router } from 'express';
import { getProfile, createProfile, updateProfile } from '../controllers/profileController.js';
const router = Router();
router.get('/:userId', getProfile);    // GET /api/profiles/:userId
router.post('/', createProfile);       // POST /api/profiles
router.put('/:userId', updateProfile); // PUT /api/profiles/:userId
export default router;