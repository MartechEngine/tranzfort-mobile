import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import authRoutes from './routes/authRoutes.js';
import userRoutes from './routes/userRoutes.js';
import loadRoutes from './routes/loadRoutes.js';
import chatRoutes from './routes/chatRoutes.js';
import verificationRoutes from './routes/verificationRoutes.js';
import adminRoutes from './routes/adminRoutes.js';
import paymentRoutes from './routes/paymentRoutes.js';
import { initWorkers } from './services/workerService.js';
import { adminJwtMiddleware } from './middleware/adminJwtMiddleware.js';
import { adminLogin } from './controllers/adminAuthController.js';

dotenv.config();

const app = express();
const port = process.env.PORT || 3000;

app.use(cors());
app.use(express.json());

// Local Admin JWT (optional)
app.use(adminJwtMiddleware);

// Local Admin Login (optional)
app.post('/admin/login', adminLogin);

// Routes
app.use('/auth', authRoutes);
app.use('/users', userRoutes);
app.use('/loads', loadRoutes);
app.use('/chats', chatRoutes);
app.use('/verifications', verificationRoutes);
app.use('/payments', paymentRoutes);
app.use('/admin', adminRoutes);

// Initialize Workers
initWorkers();

app.get('/', (req, res) => {
  res.send('tranZfort API is running');
});

app.listen(port, () => {
  console.log(`Server is running on port ${port}`);
});
