export type VerificationStatus = 'PENDING' | 'APPROVED' | 'REJECTED';

export interface User {
  id: string;
  phone: string;
  role: 'SUPPLIER' | 'TRUCKER' | 'ADMIN';
  created_at: string;
}

export interface VerificationRequest {
  id: string;
  user_id: string;
  document_url: string;
  document_type: string;
  status: VerificationStatus;
  admin_notes?: string;
  created_at: string;
  users: Pick<User, 'phone' | 'role'>;
}

export interface Load {
  id: string;
  supplier_id: string;
  pickup_location: { city: string };
  drop_location: { city: string };
  material_type: string;
  weight_mt: number;
  status: 'ACTIVE' | 'EXPIRED' | 'CLOSED';
  created_at: string;
  supplier_profiles?: {
    company_name?: string;
    owner_name?: string;
  };
}
