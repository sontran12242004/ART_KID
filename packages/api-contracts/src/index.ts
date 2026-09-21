/**
 * @artkids/api-contracts
 * Centralized API endpoints & Route definitions used by API Gateway and Frontend Clients.
 */

export const API_ROUTES = {
  AUTH: {
    REGISTER: '/api/v1/auth/register',
    LOGIN: '/api/v1/auth/login',
    ME: '/api/v1/auth/me',
    VERIFY_PIN: '/api/v1/auth/kid-pin/verify',
    UPDATE_PIN: '/api/v1/auth/kid-pin/update',
  },
  COURSES: {
    LIST: '/api/v1/courses',
    DETAIL: (courseId: string) => `/api/v1/courses/${courseId}`,
    LESSONS: (courseId: string) => `/api/v1/courses/${courseId}/lessons`,
    PROGRESS: '/api/v1/courses/progress',
  },
  COMMERCE: {
    PLANS: '/api/v1/commerce/plans',
    CHECKOUT: '/api/v1/commerce/checkout',
    ORDERS: '/api/v1/commerce/orders',
  },
  INVENTORY: {
    STOCK: '/api/v1/inventory/stock',
    CHECK_AVAILABILITY: (sku: string) => `/api/v1/inventory/stock/${sku}`,
    RESERVE: '/api/v1/inventory/reserve',
  },
  FULFILLMENT: {
    CREATE_SHIPMENT: '/api/v1/fulfillment/shipments',
    TRACK: (trackingNumber: string) => `/api/v1/fulfillment/tracking/${trackingNumber}`,
    WEBHOOK: '/api/v1/fulfillment/webhook',
  },
  AI_GENERATION: {
    SUBMIT_DRAWING: '/api/v1/ai/generate',
    JOB_STATUS: (jobId: string) => `/api/v1/ai/jobs/${jobId}`,
    CREATURES: '/api/v1/ai/creatures',
  },
} as const;
