/**
 * @artkids/shared-types
 * Shared DTOs and schemas used across Flutter App, Web Apps, and Backend Services.
 */

// ==========================================
// 1. User & Auth DTOs
// ==========================================
export type UserRole = 'parent' | 'admin' | 'instructor';

export interface UserDto {
  id: string;
  email: string;
  fullName: string;
  phoneNumber?: string;
  avatarUrl?: string;
  role: UserRole;
  createdAt: string;
}

export interface ChildProfileDto {
  id: string;
  parentId: string;
  name: string;
  birthYear: number;
  avatarUrl?: string;
  kidPinHash?: string;
  createdAt: string;
}

// ==========================================
// 2. Course & Curriculum DTOs
// ==========================================
export interface CourseDto {
  id: string;
  title: string;
  description: string;
  thumbnailUrl?: string;
  ageRange: '4–6 tuổi' | '5–8 tuổi' | '6–10 tuổi' | '7–12 tuổi';
  priceVnd: number;
  includesPhysicalKit: boolean;
  totalLessons: number;
}

export interface LessonDto {
  id: string;
  courseId: string;
  title: string;
  orderIndex: number;
  videoUrl?: string;
  practiceInstructions?: string;
}

// ==========================================
// 3. Commerce & Orders DTOs
// ==========================================
export type OrderStatus = 'pending' | 'paid' | 'processing' | 'shipped' | 'delivered' | 'cancelled';

export interface OrderItemDto {
  itemId: string;
  itemType: 'course' | 'subscription' | 'kit';
  title: string;
  quantity: number;
  unitPriceVnd: number;
}

export interface OrderDto {
  id: string;
  parentId: string;
  items: OrderItemDto[];
  totalAmountVnd: number;
  status: OrderStatus;
  shippingAddress?: string;
  createdAt: string;
  paidAt?: string;
}

export interface SubscriptionPlanDto {
  id: string;
  name: string;
  priceMonthly: number;
  priceVnd: number;
  durationMonths: number;
  features: string[];
  includesKit: boolean;
  kitDeliveryIncluded: boolean;
}

// ==========================================
// 4. Inventory & Fulfillment DTOs (Separated)
// ==========================================
export interface InventorySkuDto {
  sku: string;
  kitName: string;
  quantityAvailable: number;
  quantityReserved: number;
  reorderThreshold: number;
  unitCostVnd: number;
  warehouseLocation: string;
}

export type DeliveryStatus = 'ordered' | 'packed' | 'shipping' | 'delivered' | 'returned';

export interface FulfillmentOrderDto {
  id: string;
  orderId: string;
  parentId: string;
  kitSku: string;
  kitName: string;
  carrier: 'VNPost' | 'GHN' | 'GHTK';
  trackingNumber: string;
  status: DeliveryStatus;
  shippingAddress: string;
  recipientName: string;
  recipientPhone: string;
  estimatedDeliveryDate?: string;
  shippedAt?: string;
  deliveredAt?: string;
}

// ==========================================
// 5. AI Generation & Creature DTOs
// ==========================================
export type AiJobStatus = 'queued' | 'processing' | 'completed' | 'failed';

export interface AiGenerationJobDto {
  jobId: string;
  childId: string;
  drawingImageUrl: string;
  status: AiJobStatus;
  creatureType?: string;
  creatureName?: string;
  animation2dUrl?: string;
  model3dGlbUrl?: string;
  audioVoiceUrl?: string;
  cheeringMessage?: string;
  errorMessage?: string;
  createdAt: string;
  completedAt?: string;
}

// ==========================================
// 6. Achievement Badge DTOs
// ==========================================
export type BadgeCategory = 'habit' | 'achievement' | 'skill' | 'special';

export interface BadgeDto {
  order: number;
  id: string;
  title: string;
  emoji: string;
  condition: string;
  meaning: string;
  category: BadgeCategory;
  modelGlbPath?: string;
  isUnlocked: boolean;
  currentProgress: number;
  maxProgress: number;
}
