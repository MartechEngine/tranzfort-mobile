import type { Request, Response } from 'express';
import crypto from 'crypto';

type VerificationPaymentStatus = 'UNPAID' | 'CREATED' | 'PAID';

type VerificationPaymentRecord = {
  userId: string;
  paymentId: string;
  status: VerificationPaymentStatus;
  amount: number;
  currency: string;
  createdAt: string;
  paidAt?: string;
};

const verificationPayments = new Map<string, VerificationPaymentRecord>();

const getFeeAmount = (): number => {
  const raw = process.env.VERIFICATION_FEE_INR;
  const parsed = raw ? Number(raw) : 199;
  return Number.isFinite(parsed) ? parsed : 199;
};

export const createVerificationPayment = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });

  try {
    const amount = getFeeAmount();
    const currency = 'INR';

    const paymentId = crypto.randomUUID();
    const record: VerificationPaymentRecord = {
      userId,
      paymentId,
      status: 'CREATED',
      amount,
      currency,
      createdAt: new Date().toISOString(),
    };

    verificationPayments.set(userId, record);

    return res.status(200).json({
      paymentId,
      amount,
      currency,
      status: record.status,
      provider: 'LOCAL_DEV',
    });
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : 'Unknown error';
    return res.status(500).json({ error: message });
  }
};

export const confirmVerificationPayment = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });

  const { paymentId } = req.body ?? {};
  if (!paymentId) return res.status(400).json({ error: 'paymentId is required' });

  const record = verificationPayments.get(userId);
  if (!record || record.paymentId !== paymentId) {
    return res.status(404).json({ error: 'Payment not found' });
  }

  record.status = 'PAID';
  record.paidAt = new Date().toISOString();
  verificationPayments.set(userId, record);

  return res.status(200).json({
    paymentId: record.paymentId,
    status: record.status,
    amount: record.amount,
    currency: record.currency,
    provider: 'LOCAL_DEV',
  });
};

export const getVerificationPaymentStatus = async (req: Request, res: Response) => {
  const userId = req.user?.id;
  if (!userId) return res.status(401).json({ error: 'Unauthorized' });

  const record = verificationPayments.get(userId);
  if (!record) {
    return res.status(200).json({ status: 'UNPAID' as VerificationPaymentStatus });
  }

  return res.status(200).json({
    status: record.status,
    paymentId: record.paymentId,
    amount: record.amount,
    currency: record.currency,
    provider: 'LOCAL_DEV',
  });
};
