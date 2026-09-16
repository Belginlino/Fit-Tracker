export interface Env {
  DB: D1Database;
  PHOTOS_BUCKET: R2Bucket;
  JWT_SECRET: string;
  ENVIRONMENT?: string;
}

export interface AuthUser {
  id: string;
  email: string;
  name: string;
}

export interface ApiResponse<T = any> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}
